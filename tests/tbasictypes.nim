import unittest
import mcu_utils/basictypes


test "basic types":
  var v = 4.123.Volts
  echo "v: ", repr(v)