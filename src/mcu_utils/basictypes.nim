import std/hashes

type
  Hertz* = distinct uint
  KHertz* = distinct uint
  MHertz* = distinct uint

  Millis* = distinct int64
  Micros* = distinct int64

  Volts* = distinct float
  Amps* = distinct float

proc `~=` *[T: float32](x, y: T, eps = 1.0e-6): bool = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T, eps = 1.0e-6): bool = abs(x-y) < eps

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

basicMathBorrows(Volts)
fdivMathBorrows(Volts)
proc repr*(ts: Volts): string =
  return $(ts.float32) & "'V "

basicMathBorrows(Amps)
fdivMathBorrows(Amps)
proc repr*(ts: Amps): string =
  return $(ts.float32) & "'A "
