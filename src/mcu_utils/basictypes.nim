

type
  Hertz* = distinct uint

  Millis* = distinct int64
  Micros* = distinct int64

template basicMathBorrows(T: untyped) =
  proc `+` *(x, y: T): T {.borrow.}
  proc `-` *(x, y: T): T {.borrow.}
  proc `<` *(x, y: T): bool {.borrow.}
  proc `<=` *(x, y: T): bool {.borrow.}

basicMathBorrows(Millis)
basicMathBorrows(Micros)
