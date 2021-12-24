# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import mcu_utils/flags

test "tags test":
  const 
    GPIO_OUTPUT = 100_000'u
    GPIO_OUTPUT_INIT_HIGH = 2'u

  let f1 = join(GPIO_OUTPUT, GPIO_OUTPUT_INIT_HIGH)
  check f1 == (GPIO_OUTPUT or GPIO_OUTPUT_INIT_HIGH)

  static:
    const f4: uint = flags([GPIO_OUTPUT, GPIO_OUTPUT_INIT_HIGH])
    assert f4 == (GPIO_OUTPUT or GPIO_OUTPUT_INIT_HIGH)

  const f5: uint = Flags(GPIO_OUTPUT, GPIO_OUTPUT_INIT_HIGH)
  check f5 == (GPIO_OUTPUT or GPIO_OUTPUT_INIT_HIGH)
  echo "time: f5: ", repr f5

  # This shouldn't work since `a` is a runtime variable
  var a = 32'u
  check not compiles(Flags(GPIO_OUTPUT, a))
