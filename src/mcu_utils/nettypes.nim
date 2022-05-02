import std/hashes

when defined(zephyr):
  import nephyr/zephyr/net/znet_if

type
  NetIfId* = distinct int

  NetIfDevice* = object
    when defined(zephyr):
      raw*: ptr net_if


proc `<` *(x, y: NetIfId): bool {.borrow.}
proc `<=` *(x, y: NetIfId): bool {.borrow.}
proc `==` *(x, y: NetIfId): bool {.borrow.}
proc `hash` *(x: NetIfId): Hash {.borrow.}
proc `$` *(x: NetIfId): string {.borrow.}
proc `repr` *(x: NetIfId): string {.borrow.}
