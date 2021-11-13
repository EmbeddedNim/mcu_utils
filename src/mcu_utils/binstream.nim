
## This is a copy of some binary utils in msgpack4nim, with a few modifications
## It is still really fast.
## See below for original license:

import endians

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

when system.cpuEndian == littleEndian:
  proc takeByte*(val: uint8): uint8 {.inline.} = val
  proc takeByte*(val: uint16): uint8 {.inline.} = uint8(val and 0xFF)
  proc takeByte*(val: uint32): uint8 {.inline.} = uint8(val and 0xFF)
  proc takeByte*(val: uint64): uint8 {.inline.} = uint8(val and 0xFF)

  proc writeUint8*[ByteStream](s: ByteStream, val: uint8) =
    s.write(val)
  proc writeUint16*[ByteStream](s: ByteStream, val: uint16) =
    var res: uint16
    swapEndian16(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeUint32*[ByteStream](s: ByteStream, val: uint32) =
    var res: uint32
    swapEndian32(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeUint64*[ByteStream](s: ByteStream, val: uint64) =
    var res: uint64
    swapEndian64(addr(res), unsafeAddr(val))
    s.write(res)
  proc readUint8*[ByteStream](s: ByteStream): uint8 =
    result = cast[uint8](s.readInt8())
  proc readUint16*[ByteStream](s: ByteStream): uint16 =
    var tmp: uint16 = cast[uint16](s.readInt16())
    swapEndian16(addr(result), addr(tmp))
  proc readUint32*[ByteStream](s: ByteStream): uint32 =
    var tmp: uint32 = cast[uint32](s.readInt32())
    swapEndian32(addr(result), addr(tmp))
  proc readUint64*[ByteStream](s: ByteStream): uint64 =
    var tmp: uint64 = cast[uint64](s.readInt64())
    swapEndian64(addr(result), addr(tmp))
else:
  proc takeByte*(val: uint8): uint8 {.inline.} = val
  proc takeByte*(val: uint16): uint8 {.inline.} = (val shr 8) and 0xFF
  proc takeByte*(val: uint32): uint8 {.inline.} = (val shr 24) and 0xFF
  proc takeByte*(val: uint64): uint8 {.inline.} = uint8((val shr 56) and 0xFF)

  proc writeUint8*[ByteStream](s: ByteStream, val: uint8) = s.write(val)
  proc writeUint16*[ByteStream](s: ByteStream, val: uint16) = s.write(val)
  proc writeUint32*[ByteStream](s: ByteStream, val: uint32) = s.write(val)
  proc writeUint64*[ByteStream](s: ByteStream, val: uint64) = s.write(val)
  proc readUint8*[ByteStream](s: ByteStream): uint16 = cast[uint8](s.readChar())
  proc readUint16*[ByteStream](s: ByteStream): uint16 = cast[uint16](s.readInt16())
  proc readUint32*[ByteStream](s: ByteStream): uint32 = cast[uint32](s.readInt32())
  proc readUint64*[ByteStream](s: ByteStream): uint64 = cast[uint64](s.readInt64())

  # proc take8_8*[T:uint8|char|int8](val: T): uint8 {.inline.} = uint8(val)
  # proc take16_8*[T:uint8|char|int8](val: T): uint16 {.inline.} = uint16(val)
  # proc take32_8*[T:uint8|char|int8](val: T): uint32 {.inline.} = uint32(val)
  # proc take64_8*[T:uint8|char|int8](val: T): uint64 {.inline.} = uint64(val)
