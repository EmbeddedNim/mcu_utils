import std/hashes

type
  NetIfId* = distinct int

  NetIfDevice* = object
    when defined(zephyr):
      iface*: ptr net_if


proc `<` *(x, y: NetIfId): bool {.borrow.}
proc `<=` *(x, y: NetIfId): bool {.borrow.}
proc `==` *(x, y: NetIfId): bool {.borrow.}
proc `hash` *(x: NetIfId): Hash {.borrow.}
proc `$` *(x: NetIfId): string {.borrow.}
proc `repr` *(x: NetIfId): string {.borrow.}
