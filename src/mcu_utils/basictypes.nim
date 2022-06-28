import std/hashes

type
  Hertz* = distinct uint
  KHertz* = distinct uint
  MHertz* = distinct uint

  Millis* = distinct int64
  Micros* = distinct int64

  Bits8* = distinct int8
  Bits16* = distinct int16
  Bits24* = distinct int32
  Bits32* = distinct int32
  Bits64* = distinct int64

  UBits8* = distinct uint8
  UBits16* = distinct uint16
  UBits24* = distinct uint32
  UBits32* = distinct uint32
  UBits64* = distinct uint64

  Volts* = distinct float32
  Amps* = distinct float32
  Volts64* = distinct float64
  Amps64* = distinct float64

# import ryu/ryu_single_all

proc toString*[F](v: F): string =
  result = f2s(v.float32)
 
proc `~=` *[T: float32](x, y: T, eps = 1.0e-6): bool = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T, eps = 1.0e-6): bool = abs(x-y) < eps

proc `setSigned=`*[T: SomeInteger](x: var Bits16, val: T) = 
  x = Bits16( (int16(val) shl 16) shr 16)
proc `setSigned=`*[T: SomeInteger](x: var Bits24, val: T) = 
  x = Bits24( (int32(val) shl 8) shr 8)
proc `setSigned=`*[T: SomeInteger](x: var Bits32, val: T) = 
  x = Bits32( (int32(val) shl 8) shr 8)
proc `setSigned=`*[T: SomeInteger](x: var Bits64, val: T) = 
  x = Bits64( (int64(val) shl 8) shr 8)

template basicMathBorrows(T: untyped) =
  proc `+` *(x, y: T): T {.borrow.}
  proc `-` *(x, y: T): T {.borrow.}
  proc `<` *(x, y: T): bool {.borrow.}
  proc `<=` *(x, y: T): bool {.borrow.}
  proc `==` *(x, y: T): bool {.borrow.}
  proc `+=` *(x: var T, y: T) {.borrow.}
  proc `-=` *(x: var T, y: T) {.borrow.}
  proc `hash` *(x: T): Hash {.borrow.}
template divMathBorrows(T: untyped) =
  proc `mod` *(x, y: T): T {.borrow.}
  proc `div` *(x, y: T): T {.borrow.}
template fdivMathBorrows(T: untyped) =
  proc `/` *(x, y: T): T {.borrow.}
  proc `/=` *(x: var T, y: T) {.borrow.}
  proc `~=` *(x, y: T, eps = 1.0e-6): bool {.borrow.}

basicMathBorrows(Millis)
divMathBorrows(Millis)
proc repr*(ts: Millis): string =
  return $(ts.int) & "'ms "

basicMathBorrows(Micros)
divMathBorrows(Micros)
proc repr*(ts: Micros): string =
  return $(ts.int) & "'us "

basicMathBorrows(Bits16)
divMathBorrows(Bits16)
proc repr*(ts: Bits16): string =
  return $(ts.int16) & "'Bt16 "

basicMathBorrows(Bits24)
divMathBorrows(Bits24)
proc repr*(ts: Bits24): string =
  return $(ts.int32) & "'Bt24 "

basicMathBorrows(Bits32)
divMathBorrows(Bits32)
proc repr*(ts: Bits32): string =
  return $(ts.int32) & "'Bt32 "

basicMathBorrows(Bits64)
divMathBorrows(Bits64)
proc repr*(ts: Bits64): string =
  return $(ts.int64) & "'Bt64 "

basicMathBorrows(UBits16)
divMathBorrows(UBits16)
proc repr*(ts: UBits16): string =
  return $(ts.uint16) & "'UBt16 "

basicMathBorrows(UBits24)
divMathBorrows(UBits24)
proc repr*(ts: UBits24): string =
  return $(ts.uint32) & "'UBt24 "

basicMathBorrows(UBits32)
divMathBorrows(UBits32)
proc repr*(ts: UBits32): string =
  return $(ts.uint32) & "'UBt32 "

basicMathBorrows(UBits64)
divMathBorrows(UBits64)
proc repr*(ts: UBits64): string =
  return $(ts.uint64) & "'UBt64 "

proc toString(val: float32|float64|float): string =
  result = ""

basicMathBorrows(Volts)
fdivMathBorrows(Volts)
import std/strformat

proc repr*(ts: Volts): string =
  return $(ts.toString()) & "'V "

basicMathBorrows(Amps)
fdivMathBorrows(Amps)
proc repr*(ts: Amps): string =
  return $(ts.toString()) & "'A "

basicMathBorrows(Volts64)
fdivMathBorrows(Volts64)
proc repr*(ts: Volts64): string =
  return $(ts.toString()) & "'V "

basicMathBorrows(Amps64)
fdivMathBorrows(Amps64)
proc repr*(ts: Amps64): string =
  return $(ts.toString()) & "'A "
