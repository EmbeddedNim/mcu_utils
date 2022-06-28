
include ryu_single_all

# proc f2s_c2*(s: pointer, l: ptr cint, f: ptr float32) {.importc: "f2s_c1", nodecl.}
# proc f2s_n*(f: float32): string =
#   var len: cint = 128
#   result = newString(len)
#   var x: float32 = f
#   f2s_c2(result[0].addr, len.addr, x.addr)
#   result.setLen(len)

template `$`*(v: float32): string =
  f2s(v.float32)
template `$`*(v: float64): string =
  f2s(v.float32)
template `$`*(v: float): string =
  f2s(v.float32)
 