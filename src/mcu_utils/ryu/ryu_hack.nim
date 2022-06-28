import ryu_single_all

proc float_to_string_impl(s: ptr string, f: ptr float32) {.exportc: "float_to_string_impl".} =
  ## hack to get around limitations with print floats with libc on some mcu's 
  var res = f2s(f[])
  s[] = res
