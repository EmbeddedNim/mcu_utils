import std/hashes

type
  Hertz* = distinct uint
  KHertz* = distinct uint
  MHertz* = distinct uint

  Millis* = distinct int64
  Micros* = distinct int64

template basicMathBorrows(T: untyped) =
  proc `+` *(x, y: T): T {.borrow.}
  proc `-` *(x, y: T): T {.borrow.}
  proc `<` *(x, y: T): bool {.borrow.}
  proc `<=` *(x, y: T): bool {.borrow.}
  proc `==` *(x, y: T): bool {.borrow.}
  proc `hash` *(x: T): Hash {.borrow.}

basicMathBorrows(Millis)
basicMathBorrows(Micros)

proc repr*(ts: Micros): string =
  return $(ts.int) & "'us "
proc repr*(ts: Millis): string =
  return $(ts.int) & "'ms "
