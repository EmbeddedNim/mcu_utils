# Copyright 2018 Ulf Adams
#
# The contents of this file may be used under the terms of the Apache License,
# Version 2.0.
#
#    (See accompanying file LICENSE-Apache or copy at
#     http://www.apache.org/licenses/LICENSE-2.0)
#
# Alternatively, the contents of this file may be used under the terms of
# the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE-Boost or copy at
#     https://www.boost.org/LICENSE_1_0.txt)
#
# Unless required by applicable law or agreed to in writing, this software
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.

template pow5bits*(e: int32): int32 =
  # Returns if e == 0: 1 else: ceil(log_2(5^e)); requires 0 <= e <= 3528.
  # This approximation works up to the point that the multiplication overflows at e = 3529.
  # If the multiplication were done in 64 bits, it would fail at 5^4004 which is just greater
  # than 2^9297.
  assert e in 0..3528
  int32(((e.uint32 * 1217359) shr 19) + 1)

template log10Pow2*(e: int32): uint32 =
  # Returns floor(log_10(2^e)); requires 0 <= e <= 1650.
  # The first value this approximation fails for is 2^1651 which is just greater than 10^297.
  assert e in 0..1650
  (e.uint32 * 78913) shr 18

template log10Pow5*(e: int32): uint32 =
  # Returns floor(log_10(5^e)); requires 0 <= e <= 2620.
  # The first value this approximation fails for is 5^2621 which is just greater than 10^1832.
  assert e in 0..2620
  (e.uint32 * 732923) shr 20

proc copy_special_str*(resul: var string, sign, exponent, mantissa: bool): int32 {.inline.} =
  if mantissa:
    resul = "NaN"
    return 3
  if sign:
    resul[0] = '-'
  if exponent:
    resul[ord(sign)..<ord(sign)+8] = "Infinity"
    return int32(sign) + 8
  resul[ord(sign)..<ord(sign)+3] = "0E0"
  return int32(sign) + 3