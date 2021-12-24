import macros

proc join*[T](flags: varargs[T]): T =
  for flag in flags:
    result = result or flag


proc flags*[T](values: static openArray[T]): T =
  result =
    static:
      join(values)

template Flags*(values: varargs[untyped]): untyped =
  const val = 
    static:
      join(values)
  val
