import std/hashes

type
  Hertz* = distinct uint
  KHertz* = distinct uint
  MHertz* = distinct uint

  Millis* = distinct int64
  Micros* = distinct int64

  Volts* = distinct float
  Amps* = distinct float

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
  proc `~=` *[T: float32](x, y: T, eps = 1.0e-6): bool = abs(x.float32-y.float32) < eps
  proc `~=` *[T: float64](x, y: T, eps = 1.0e-6): bool = abs(x.float64-y.float64) < eps

basicMathBorrows(Millis)
divMathBorrows(Millis)
proc repr*(ts: Millis): string =
  return $(ts.int) & "'ms "

basicMathBorrows(Micros)
divMathBorrows(Micros)
proc repr*(ts: Micros): string =
  return $(ts.int) & "'us "

basicMathBorrows(Volts)
fdivMathBorrows(Volts)
proc repr*(ts: Volts): string =
  return $(ts.float32) & "'v "

basicMathBorrows(Amps)
fdivMathBorrows(Amps)
proc repr*(ts: Amps): string =
  return $(ts.float32) & "'a "
