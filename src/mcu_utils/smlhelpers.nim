import std/[os, json, strformat, sequtils, strutils, tables]
import std/random
import std/json

import msgpack4nim
import msgpack4nim/msgpack2json

when defined(zephyr):
  import nephyr/[nets]

import stew/byteutils
include mcu_utils/threads
import mcu_utils/[logging, timeutils, msgbuffer, allocstats]


let
  MacAddressStr* =
    when defined(zephyr):
      getDefaultInterface().hwMacAddress().foldl(a & b.toHex(2) & ":", "").toLowerAscii[0..^2]
    else:
      "11:22:33:44:55:66"
  # TODO: auto detect active channels? align it with streams definition
  # activeChannels = [0]

template generateTableNames(format: string, rng: HSlice[int, int]): Table[int, string] = 
  var result = initTable[int, string](rng.len())
  for i in rng.a..rng.b:
    result[i] = format % [$i]
  result

let
  voltageNames* = generateTableNames("ch$1.voltage", 0..7)
  currentNames* = generateTableNames("ch$1.current", 0..7)
  UnitAmps* = "A"
  UnitVolts* = "V"

## =========  Basic SmlMeasurement ========= ##
type
  SmlReadingKind* = enum Normal, BaseNT

  SmlReading* = object
    kind*: SmlReadingKind
    name*: string
    unit*: string
    ts*: TimeSML
    value*: float
  
proc pack_type*[ByteStream](s: ByteStream, x: SmlReading) =
  case x.kind:
  of Normal:
    s.pack_map(4)
    s.pack("n")
    s.pack(x.name)
    s.pack("t")
    s.pack(x.ts.float64) # let the compiler decide
    s.pack("v")
    s.pack(x.value) # let the compiler decide
    s.pack("u")
    s.pack(x.unit) # let the compiler decide
  of BaseNT:
    s.pack_map(2)
    s.pack("bn")
    s.pack(x.name)
    s.pack("bt")
    s.pack(x.ts.float64) # let the compiler decide

when isMainModule:

  import ../adcs/ads131

  proc testSmlGen() =
    var batch = newSeq[AdcReading](1)

    for i in 0..<batch.len():
      batch[i].ts = currTimeSenML()
      batch[i].sample_count = 6
      for j in 0..<batch[i].sample_count:
        batch[i].samples[j] = rand(1000).int32

    echo "testing sml pack"
    echo fmt"{voltageNames=}"
    echo fmt"{currentNames=}"

    var ss = MsgBuffer.init()
    logAllocStats(lvlInfo):
      let ts = currTimeSenML()
      var smls = newSeqOfCap[SmlReading](2*batch.len())
      smls.add SmlReading(kind: BaseNT, name: MacAddressStr, ts: ts)
      for reading in batch:
        for i in 0..<reading.sample_count:
          let tsr = ts - reading.ts
          let vs = reading.samples[i].float32.toVoltage(gain=1, r1=0.0'f32, r2=1.0'f32)
          let cs = reading.samples[i].float32.toCurrent(gain=1, senseR=110.0'f32)
          echo fmt"{vs=} {cs=}"
          smls.add SmlReading(kind: Normal, name: voltageNames[i], unit: UnitVolts, ts: tsr, value: vs)
          smls.add SmlReading(kind: Normal, name: currentNames[i], unit: UnitAmps, ts: tsr, value: cs)

      ss.pack(smls)

    echo fmt"msgbuffer serialized: bytes({ss.data.len()}): {ss.data.toHex()}"
    echo "msgbuffer de-serialized: ", ss.data.toJsonNode().pretty()

  proc testSmlGenOld() =
    var batch = newSeq[AdcReading](1)

    for i in 0..<batch.len():
      batch[i].ts = currTimeSenML()
      batch[i].sample_count = 6
      for j in 0..<batch[i].sample_count:
        batch[i].samples[j] = rand(1000).int32

    echo "testing sml pack"
    echo fmt"{voltageNames=}"
    echo fmt"{currentNames=}"

    var ss = MsgBuffer.init()
    logAllocStats(lvlInfo):
      let ts = currTimeSenML()
      var res = %* [
        {"bn": MacAddressStr, "bt": ts.float64}
      ]

      var smls = newSeqOfCap[SmlReading](2*batch.len())
      smls.add SmlReading(kind: BaseNT, name: MacAddressStr, ts: ts)

      for reading in batch:
        for i in 0..<reading.sample_count:
          let tsr = ts - reading.ts
          let vs = reading.samples[i].float32.toVoltage(gain=1, r1=0.0'f32, r2=1.0'f32)
          let cs = reading.samples[i].float32.toCurrent(gain=1, senseR=110.0'f32)
          res.add(%* {"n": fmt"ch{i}.voltage", "u": "V", "t": tsr, "v": vs})
          res.add(%* {"n": fmt"ch{i}.current", "u": "A", "t": tsr, "v": cs})

      ss.fromJsonNode(res)

    echo fmt"msgbuffer serialized: bytes({ss.data.len()}): {ss.data.toHex()}"
    echo "msgbuffer de-serialized: ", ss.data.toJsonNode().pretty()

  testSmlGen()
  testSmlGenOld()