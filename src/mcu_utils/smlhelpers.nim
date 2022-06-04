import std/[os, json, strformat, sequtils, strutils, tables]
import std/random
import std/json

import msgpack4nim
import msgpack4nim/msgpack2json
import msgpack4nim/msgpack2any

import stew/byteutils
import logging, timeutils, msgbuffer, allocstats

#  +---------------+-------+------------+------------+------------+
#  |          Name | Label | CBOR Label | JSON Type  | XML Type   |
#  +---------------+-------+------------+------------+------------+
#  |     Base Name | bn    |         -2 | String     | string     |
#  |     Base Time | bt    |         -3 | Number     | double     |
#  |     Base Unit | bu    |         -4 | String     | string     |
#  |    Base Value | bv    |         -5 | Number     | double     |
#  |      Base Sum | bs    |         -6 | Number     | double     |
#  |  Base Version | bver  |         -1 | Number     | int        |
#  |          Name | n     |          0 | String     | string     |
#  |          Unit | u     |          1 | String     | string     |
#  |         Value | v     |          2 | Number     | double     |
#  |  String Value | vs    |          3 | String     | string     |
#  | Boolean Value | vb    |          4 | Boolean    | boolean    |
#  |    Data Value | vd    |          8 | String (*) | string (*) |
#  |           Sum | s     |          5 | Number     | double     |
#  |          Time | t     |          6 | Number     | double     |
#  |   Update Time | ut    |          7 | Number     | double     |
#  +---------------+-------+------------+------------+------------+


type
  SmlFields* = enum
    bs = -6,
    bv = -5,
    bu = -4,
    bt = -3,
    bn = -2,
    bver = -1,
    n = 0,
    u = 1,
    v = 2,
    vs = 3,
    vb = 4,
    s = 5,
    t = 6,
    ut = 7,
    vd = 8

## =========  Basic SmlMeasurement ========= ##
type
  SmlReadingKind* = enum NormalNTVU, NormalNVU, BaseNT

  SmlReading* = object
    kind*: SmlReadingKind
    name*: string
    unit*: string
    ts*: TimeSML
    value*: float
  
proc pack_type*[ByteStream](s: ByteStream, x: SmlReading) =
  case x.kind:
  of NormalNTVU:
    s.pack_map(4)
    s.pack("n")
    s.pack(x.name)
    s.pack("t")
    s.pack(x.ts.float64) # let the compiler decide
    s.pack("v")
    s.pack(x.value) # let the compiler decide
    s.pack("u")
    s.pack(x.unit) # let the compiler decide
  of NormalNVU:
    s.pack_map(3)
    s.pack("n")
    s.pack(x.name)
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

type
  SmlReadingI* = object
    kind*: SmlReadingKind
    name*: string
    unit*: char
    ts*: TimeSML
    value*: float
  
proc pack_type*[ByteStream](s: ByteStream, x: SmlReadingI) =
  case x.kind:
  of NormalNTVU:
    s.pack_map(4)
    s.pack(SmlFields.n)
    s.pack(x.name)
    s.pack(SmlFields.t)
    s.pack(x.ts.float64) # let the compiler decide
    s.pack(SmlFields.v)
    s.pack(x.value) # let the compiler decide
    s.pack(SmlFields.u)
    s.pack(x.unit) # let the compiler decide
  of NormalNVU:
    s.pack_map(3)
    s.pack(SmlFields.n)
    s.pack(x.name)
    s.pack(SmlFields.v)
    s.pack(x.value) # let the compiler decide
    s.pack(SmlFields.u)
    s.pack(x.unit) # let the compiler decide
  of BaseNT:
    s.pack_map(2)
    s.pack(SmlFields.bn)
    s.pack(x.name)
    s.pack(SmlFields.bt)
    s.pack(x.ts.float64) # let the compiler decide

when isMainModule:

  let MacAddressStr = "00:11:22:33:44:55"
  type
    AdcReading = object
      ts*: TimeSML
      sample_count*: int
      samples*: array[8, int32]

  proc testSmlGen() =
    var batch = newSeq[AdcReading](1)

    for i in 0..<batch.len():
      batch[i].ts = currTimeSenML()
      batch[i].sample_count = 6
      for j in 0..<batch[i].sample_count:
        batch[i].samples[j] = rand(1000).int32

    var ss = MsgBuffer.init()
    logAllocStats(lvlInfo):
      let ts = currTimeSenML()
      var smls = newSeqOfCap[SmlReading](2*batch.len())
      smls.add SmlReading(kind: BaseNT, name: MacAddressStr, ts: ts)
      for reading in batch:
        for i in 0..<reading.sample_count:
          let tsr = ts - reading.ts
          let vs = reading.samples[i].float32 / 10.0 + 3.3
          let cs = reading.samples[i].float32 / 14.0 + 1.0
          smls.add SmlReading(kind: NormalNVU, name: fmt"ch{i}.v", unit: "V", ts: tsr, value: vs)
          smls.add SmlReading(kind: NormalNVU, name: fmt"ch{i}.c", unit: "A", ts: tsr, value: cs)

      ss.pack(smls)

    echo fmt"msgbuffer serialized: bytes({ss.data.len()}): {ss.data.toHex()}"
    echo "msgbuffer de-serialized: ", ss.data.toJsonNode().pretty()

  proc testSmlGenI() =
    var batch = newSeq[AdcReading](1)

    for i in 0..<batch.len():
      batch[i].ts = currTimeSenML()
      batch[i].sample_count = 6
      for j in 0..<batch[i].sample_count:
        batch[i].samples[j] = rand(1000).int32

    var ss = MsgBuffer.init()
    logAllocStats(lvlInfo):
      let ts = currTimeSenML()
      var smls = newSeqOfCap[SmlReadingI](2*batch.len())
      smls.add SmlReadingI(kind: BaseNT, name: MacAddressStr, ts: ts)
      for reading in batch:
        for i in 0..<reading.sample_count:
          let tsr = ts - reading.ts
          let vs = reading.samples[i].float32 / 10.0 + 3.3
          let cs = reading.samples[i].float32 / 14.0 + 1.0
          smls.add SmlReadingI(kind: NormalNVU, name: fmt"ch{i}.v", unit: 'V', ts: tsr, value: vs)
          smls.add SmlReadingI(kind: NormalNVU, name: fmt"ch{i}.c", unit: 'A', ts: tsr, value: cs)

      ss.pack(smls)

    echo fmt"msgbuffer serialized: bytes({ss.data.len()}): {ss.data.toHex()}"
    echo "msgbuffer de-serialized: ", ss.data.toAny().pretty()

  proc testSmlGenOld() =
    var batch = newSeq[AdcReading](1)

    for i in 0..<batch.len():
      batch[i].ts = currTimeSenML()
      batch[i].sample_count = 6
      for j in 0..<batch[i].sample_count:
        batch[i].samples[j] = rand(1000).int32

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
          let vs = reading.samples[i].float32 / 10.0 + 3.3
          let cs = reading.samples[i].float32 / 14.0 + 1.0
          res.add(%* {"n": fmt"ch{i}.v", "u": "V", "t": tsr, "v": vs})
          res.add(%* {"n": fmt"ch{i}.c", "u": "A", "t": tsr, "v": cs})

      ss.fromJsonNode(res)

    echo fmt"msgbuffer serialized: bytes({ss.data.len()}): {ss.data.toHex()}"
    echo "msgbuffer de-serialized: ", ss.data.toJsonNode().pretty()

  echo "## ======================= testSmlGen ======================= ## "
  testSmlGen()
  echo "## ======================= testSmlGenI ====================== ## "
  testSmlGenI()
  echo "## ======================= testSmlGenOld ==================== ## "
  testSmlGenOld()