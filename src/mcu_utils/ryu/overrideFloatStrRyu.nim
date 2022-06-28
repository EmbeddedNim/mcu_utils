
when isMainModule:
  ## hack to get around limitations with print floats with libc on some mcu's 
  import mcu_utils/ryu/ryu_hack

proc float_to_string_wrap*(
  s: ptr string,
  f: ptr float32
) {.importc: "float_to_string_impl", nodecl.} ##\
  ## essentially we treat float_to_string_impl as an statically linked lib
  ## long term that'd probably be better but requires linking on zephyr, etc. 

proc f2s_n*(f: float32): string =
  var len: cint = 128
  result = newString(len)
  var x: float32 = f
  float_to_string_wrap(result.addr, x.addr)
  result.setLen(len)

template `$`*(v: float32): string =
  f2s_n(v.float32)
template `$`*(v: float64): string =
  f2s_n(v.float32)
template `$`*(v: float): string =
  f2s_n(v.float32)
 