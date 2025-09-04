## This is a copy of the MsgStream in msgpack4nim, with a few modifications
## It is still really fast.
## See below for original license:

# MessagePack implementation written in nim
#
# Copyright (c) 2015-2019 Andri Lim
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#
#-------------------------------------

when not declared SomeFloat:
  type
    SomeFloat = SomeReal

import macros, streams
import binstream

export binstream, streams

type
  EncodingMode* = enum
    MSGPACK_OBJ_TO_DEFAULT
    MSGPACK_OBJ_TO_ARRAY
    MSGPACK_OBJ_TO_MAP
    MSGPACK_OBJ_TO_STREAM

  MsgBuffer* = ref object of StringStreamObj
    encodingMode: EncodingMode

{.push gcsafe.}

proc init*(x: typedesc[MsgBuffer], data: sink string, encodingMode = MSGPACK_OBJ_TO_DEFAULT): MsgBuffer =
  result = new x
  # Initialize StringStream base by copying fields from a new StringStream:
  var ss = newStringStream()
  result.data = data
  result.closeImpl = ss.closeImpl
  result.atEndImpl = ss.atEndImpl
  result.setPositionImpl = ss.setPositionImpl
  result.getPositionImpl = ss.getPositionImpl
  result.readDataStrImpl = ss.readDataStrImpl
  when nimvm:
    discard
  else:
    result.readDataImpl = ss.readDataImpl
    result.peekDataImpl = ss.peekDataImpl
    result.writeDataImpl = ss.writeDataImpl
  result.encodingMode = encodingMode

proc init*(x: typedesc[MsgBuffer], cap: int = 0, encodingMode = MSGPACK_OBJ_TO_DEFAULT): MsgBuffer =
  result = init(x, newStringOfCap(cap), encodingMode)

proc initMsgStream*(cap: int = 0, encodingMode = MSGPACK_OBJ_TO_DEFAULT): MsgBuffer {.deprecated: "use MsgBuffer.init instead".} =
  result = MsgBuffer.init(cap, encodingMode)

proc initMsgStream*(data: string, encodingMode = MSGPACK_OBJ_TO_DEFAULT): MsgBuffer {.deprecated: "use MsgBuffer.init instead".} =
  result = MsgBuffer.init(data, encodingMode)

proc setEncodingMode*(s: MsgBuffer, encodingMode: EncodingMode) =
  s.encodingMode = encodingMode

proc getEncodingMode*(s: MsgBuffer): EncodingMode =
  s.encodingMode


proc readStrRemaining*(s: MsgBuffer): string =
  let ln = s.data.len() - s.getPosition() 
  result = newString(ln)
  if ln != 0:
    var rl = s.readData(addr(result[0]), ln)
    if rl != ln: raise newException(IOError, "string len mismatch")

proc readMsgBuffer*(s: MsgBuffer, length: int): MsgBuffer =
  result = MsgBuffer.init(length)
  if length != 0:
    var L = s.readData(addr(result.data[0]), length)
    result.setPosition(L)

proc readMsgBufferRemaining*(s: MsgBuffer): MsgBuffer =
  result = s.readMsgBuffer(s.data.len() - s.getPosition())

when false:
  proc getParamIdent(n: NimNode): NimNode =
    n.expectKind({nnkIdent, nnkVarTy, nnkSym})
    if n.kind in {nnkIdent, nnkSym}:
      result = n
    else:
      result = n[0]

  proc hasDistinctImpl*(w: NimNode, z: NimNode): bool =
    for k in w:
      let p = k.getImpl()[3][2][1]
      if p.kind in {nnkIdent, nnkVarTy, nnkSym}:
        let paramIdent = getParamIdent(p)
        if eqIdent(paramIdent, z): return true

  proc needToSkip(typ: NimNode | typedesc, w: NimNode): bool {.compileTime.} =
    let z = getType(typ)[1]

    if z.kind == nnkSym:
      if hasDistinctImpl(w, z): return true

    if z.kind != nnkSym: return false
    let impl = getImpl(z)
    if impl.kind != nnkTypeDef: return false
    if impl[2].kind != nnkDistinctTy: return false
    if impl[0].kind != nnkPragmaExpr: return false
    let prag = impl[0][1][0]
    result = eqIdent("skipUndistinct", prag)

  macro undistinctImpl*(x: typed, typ: typedesc, w: typed): untyped =
    #this macro convert any distinct types to it's base type
    var ty = getType(x)
    if needToSkip(typ, w):
      result = x
      return
    var isDistinct = ty.typekind == ntyDistinct
    if isDistinct:
      let parent = ty[1]
      result = quote do: `parent`(`x`)
    else:
      result = x

  template undistinct_pack*(x: typed): untyped =
    undistinctImpl(x, type(x), bindSym("pack_type", brForceOpen))

  template undistinct_unpack*(x: typed): untyped =
    undistinctImpl(x, type(x), bindSym("unpack_type", brForceOpen))
