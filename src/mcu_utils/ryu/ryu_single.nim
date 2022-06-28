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

# Options:
# -d:RYU_DEBUG Generate verbose debugging output to stdout.
#
# -d:RYU_OPTIMIZE_SIZE Use smaller lookup tables. Instead of storing every
#     required power of 5, only store every 26th entry, and compute intermediate
#     values with a multiplication. This reduces the lookup table size by about
#     10x (only one case, and only double) at the cost of some performance.
#
# -d:RYU_FLOAT_FULL_TABLE

import common
import digit_table

import d2s_small_table
const FLOAT_POW5_INV_BITCOUNT = (DOUBLE_POW5_INV_BITCOUNT - 64)
const FLOAT_POW5_BITCOUNT = (DOUBLE_POW5_BITCOUNT - 64)

const FLOAT_MANTISSA_BITS = 23
const FLOAT_EXPONENT_BITS = 8
const FLOAT_BIAS = 127

proc decimalLength9*(v: uint32): uint32 {.inline.} =
  # Returns the number of decimal digits in v, which must not contain more than 9 digits.
  # Function precondition: v is not a 10-digit number.
  # (9 digits are sufficient for round-tripping.)
  assert v < 1000000000
  if v >= 100000000: 9
  elif v >= 10000000: 8
  elif v >= 1000000: 7
  elif v >= 100000: 6
  elif v >= 10000: 5
  elif v >= 1000: 4
  elif v >= 100: 3
  elif v >= 10: 2
  else: 1

proc pow5factor_32(value: uint32): uint32 {.inline.} =
  var value = value
  while true:
    assert value != 0
    let q = value div 5
    let r = value mod 5
    if r != 0:
      break
    value = q
    inc result

template multipleOfPowerOf5_32(value: uint32, p: uint32): bool = pow5factor_32(value) >= p
  # Returns true if value is divisible by 5^p.

template multipleOfPowerOf2_32(value: uint32, p: uint32): bool = (value and ((1u shl p) - 1)) == 0
  # Returns true if value is divisible by 2^p.

proc mulShift32(m: uint32, factor: uint64, shift: int32): uint32 {.inline.} =
  # It seems to be slightly faster to avoid uint128_t here, although the
  # generated code for uint128_t looks slightly nicer.
  assert shift > 32

  # The casts here help MSVC to avoid calls to the __allmul library
  # function.
  let factorLo = factor.uint32
  let factorHi = uint32(factor shr 32)
  let bits0 = m.uint64 * factorLo
  let bits1 = m.uint64 * factorHi

  when defined(RYU_32_BIT_PLATFORM):
    # On 32-bit platforms we can avoid a 64-bit shift-right since we only
    # need the upper 32 bits of the result and the shift value is > 32.
    let bits0Hi = uint32(bits0 shr 32)
    var bits1Lo = bits1.uint32
    var bits1Hi = uint32(bits1 shr 32)
    bits1Lo += bits0Hi
    bits1Hi += (bits1Lo < bits0Hi)
    let s = shift - 32
    (bits1Hi shl (32 - s)) or (bits1Lo shr s)
  else: # RYU_32_BIT_PLATFORM
    let sum = (bits0 shr 32) + bits1
    let shiftedSum = sum shr (shift - 32)
    assert shiftedSum <= uint32.high
    shiftedSum.uint32

proc mulPow5InvDivPow2(m: uint32, q: uint32, j: int32): uint32 {.inline.} =
  # when defined(RYU_FLOAT_FULL_TABLE):
    # mulShift32(m, FLOAT_POW5_INV_SPLIT[q], j)
  # elif defined(RYU_OPTIMIZE_SIZE):
    # The inverse multipliers are defined as [2^x / 5^y] + 1; the upper 64 bits from the double lookup
    # table are the correct bits for [2^x / 5^y], so we have to add 1 here. Note that we rely on the
    # fact that the added 1 that's already stored in the table never overflows into the upper 64 bits.
    mulShift32(m, double_computeInvPow5(q)[1] + 1, j)
  # else:
    # mulShift32(m, DOUBLE_POW5_INV_SPLIT[q][1] + 1, j)

proc mulPow5divPow2(m: uint32, i: uint32, j: int32): uint32 {.inline.} =
  # when defined(RYU_FLOAT_FULL_TABLE):
    # mulShift32(m, FLOAT_POW5_SPLIT[i], j)
  # elif defined(RYU_OPTIMIZE_SIZE):
    mulShift32(m, double_computePow5(i)[1], j)
  # else:
    # mulShift32(m, DOUBLE_POW5_SPLIT[i][1], j)

# A floating decimal representing m * 10^e.
type floating_decimal_32 = object
  mantissa: uint32
  # Decimal exponent's range is -45 to 38
  # inclusive, and can fit in a short if needed.
  exponent: int32

proc f2d(ieeeMantissa: uint32, ieeeExponent: uint32): floating_decimal_32 {.inline.} =
  var e2: int32
  var m2: uint32
  if ieeeExponent == 0:
    # We subtract 2 so that the bounds computation has 2 additional bits.
    e2 = 1 - FLOAT_BIAS - FLOAT_MANTISSA_BITS - 2
    m2 = ieeeMantissa
  else:
    e2 = ieeeExponent.int32 - FLOAT_BIAS - FLOAT_MANTISSA_BITS - 2
    m2 = (1'u32 shl FLOAT_MANTISSA_BITS) or ieeeMantissa
  let acceptBounds = (m2 and 1) == 0

  when defined(RYU_DEBUG):
    echo "-> ",m2," * 2^",e2 + 2

  # Step 2: Determine the interval of valid decimal representations.
  let mv = 4 * m2
  let mp = 4 * m2 + 2
  # Implicit bool -> int conversion. True is 1, false is 0.
  let mmShift = uint32 ord(ieeeMantissa != 0 or ieeeExponent <= 1)
  let mm = 4 * m2 - 1 - mmShift

  # Step 3: Convert to a decimal power base using 64-bit arithmetic.
  var vr, vp, vm: uint32
  var e10: int32
  var vmIsTrailingZeros = false
  var vrIsTrailingZeros = false
  var lastRemovedDigit = 0'u8
  if e2 >= 0:
    let q = log10Pow2(e2)
    e10 = q.int32
    let k = FLOAT_POW5_INV_BITCOUNT + pow5bits(q.int32) - 1
    let i = -e2 + q.int32 + k
    vr = mulPow5InvDivPow2(mv, q, i)
    vp = mulPow5InvDivPow2(mp, q, i)
    vm = mulPow5InvDivPow2(mm, q, i)
    when defined(RYU_DEBUG):
      echo mv," * 2^",e2," / 10^",q
      echo "V+=",vp,"\nV =",vr,"\nV-=",vm
    if q != 0 and (vp - 1) div 10 <= vm div 10:
      # We need to know one removed digit even if we are not going to loop below. We could use
      # q = X - 1 above, except that would require 33 bits for the result, and we've found that
      # 32-bit arithmetic is faster even on 64-bit machines.
      let l = FLOAT_POW5_INV_BITCOUNT + pow5bits(q.int32 - 1) - 1
      lastRemovedDigit = uint8(mulPow5InvDivPow2(mv, q - 1, -e2 + q.int32 - 1 + l) mod 10)
    if q <= 9:
      # The largest power of 5 that fits in 24 bits is 5^10, but q <= 9 seems to be safe as well.
      # Only one of mp, mv, and mm can be a multiple of 5, if any.
      if mv mod 5 == 0:
        vrIsTrailingZeros = multipleOfPowerOf5_32(mv, q)
      elif acceptBounds:
        vmIsTrailingZeros = multipleOfPowerOf5_32(mm, q)
      else:
        vp -= uint32 ord(multipleOfPowerOf5_32(mp, q))
  else:
    let q = log10Pow5(-e2)
    e10 = q.int32 + e2
    let i = -e2 - q.int32
    let k = pow5bits(i) - FLOAT_POW5_BITCOUNT
    var j = q.int32 - k
    vr = mulPow5divPow2(mv, i.uint32, j)
    vp = mulPow5divPow2(mp, i.uint32, j)
    vm = mulPow5divPow2(mm, i.uint32, j)
    when defined(RYU_DEBUG):
      echo mv," * 5^",-e2," / 10^",q
      echo q," ",i," ",k," ",j
      echo "V+=",vp,"\nV =",vr,"\nV-=",vm
    if q != 0 and (vp - 1) div 10 <= vm div 10:
      j = q.int32 - 1 - (pow5bits(i + 1) - FLOAT_POW5_BITCOUNT)
      lastRemovedDigit = uint8(mulPow5divPow2(mv, uint32(i + 1), j) mod 10)
    if q <= 1:
      # {vr,vp,vm} is trailing zeros if {mv,mp,mm} has at least q trailing 0 bits.
      # mv = 4 * m2, so it always has at least two trailing 0 bits.
      vrIsTrailingZeros = true
      if acceptBounds:
        # mm = mv - 1 - mmShift, so it has 1 trailing 0 bit iff mmShift == 1.
        vmIsTrailingZeros = mmShift == 1
      else:
        # mp = mv + 2, so it always has at least one trailing 0 bit.
        dec vp
    elif q < 31: # TODO(ulfjack): Use a tighter bound here.
      vrIsTrailingZeros = multipleOfPowerOf2_32(mv, q - 1)
      when defined(RYU_DEBUG):
        echo "vr is trailing zeros=",vrIsTrailingZeros
  when defined(RYU_DEBUG):
    echo "e10=",e10
    echo "V+=",vp,"\nV =",vr,"\nV-=",vm
    echo "vm is trailing zeros=",vmIsTrailingZeros
    echo "vr is trailing zeros=",vrIsTrailingZeros

  # Step 4: Find the shortest decimal representation in the interval of valid representations.
  var removed = 0'i32
  var output: uint32
  if vmIsTrailingZeros or vrIsTrailingZeros:
    # General case, which happens rarely (~4.0%).
    while vp div 10 > vm div 10:
      when false: #__clang__ # https://bugs.llvm.org/show_bug.cgi?id=23106
        # The compiler does not realize that vm mod 10 can be computed from vm / 10
        # as vm - (vm / 10) * 10.
        vmIsTrailingZeros = vmIsTrailingZeros and vm - (vm / 10) * 10 == 0
      else:
        vmIsTrailingZeros = vmIsTrailingZeros and vm mod 10 == 0
      vrIsTrailingZeros = vrIsTrailingZeros and lastRemovedDigit == 0
      lastRemovedDigit = uint8(vr mod 10)
      vr = vr div 10
      vp = vp div 10
      vm = vm div 10
      inc removed
    when defined(RYU_DEBUG):
      echo "V+=",vp,"\nV =",vr,"\nV-=",vm
      echo "d-10=",vmIsTrailingZeros
    if vmIsTrailingZeros:
      while vm mod 10 == 0:
        vrIsTrailingZeros = vrIsTrailingZeros and lastRemovedDigit == 0
        lastRemovedDigit = uint8(vr mod 10)
        vr = vr div 10
        vp = vp div 10
        vm = vm div 10
        inc removed
    when defined(RYU_DEBUG):
      echo vr," ",lastRemovedDigit
      echo "vr is trailing zeros=",vrIsTrailingZeros
    if vrIsTrailingZeros and lastRemovedDigit == 5 and vr mod 2 == 0:
      # Round even if the exact number is .....50..0.
      lastRemovedDigit = 4
    # We need to take vr + 1 if vr is outside bounds or we need to round up.
    output = vr + uint32 ord((vr == vm and (not acceptBounds or not vmIsTrailingZeros)) or lastRemovedDigit >= 5)
  else:
    # Specialized for the common case (~96.0%). Percentages below are relative to this.
    # Loop iterations below (approximately):
    # 0: 13.6%, 1: 70.7%, 2: 14.1%, 3: 1.39%, 4: 0.14%, 5+: 0.01%
    while vp div 10 > vm div 10:
      lastRemovedDigit = uint8(vr mod 10)
      vr = vr div 10
      vp = vp div 10
      vm = vm div 10
      inc removed
    when defined(RYU_DEBUG):
      echo vr," ",lastRemovedDigit
      echo "vr is trailing zeros=",vrIsTrailingZeros
    # We need to take vr + 1 if vr is outside bounds or we need to round up.
    output = vr + uint32 ord(vr == vm or lastRemovedDigit >= 5)

  result.exponent = e10 + removed
  result.mantissa = output

  when defined(RYU_DEBUG):
    echo "V+=",vp,"\nV =",vr,"\nV-=",vm
    echo "O=",output
    echo "EXP=",result.exponent

proc to_chars(v: floating_decimal_32, sign: bool, resul: var string): int32 {.inline.} =
  # Step 5: Print the decimal representation.
  if sign:
    resul[result] = '-'
    inc result

  var output = v.mantissa
  let olength = decimalLength9(output)

  when defined(RYU_DEBUG):
    echo "DIGITS=",v.mantissa
    echo "OLEN=",olength
    echo "EXP=",v.exponent.uint32 + olength

  # Print the decimal digits.
  # The following code is equivalent to:
  # for i in 0'u32..<olength - 1:
  #   let c = output mod 10; output /= 10
  #   resul[result + olength - i] = (char) ('0' + c)
  # resul[result] = '0' + output mod 10
  var i = 0'u32
  while output >= 10000:
    when false:#__clang__ # https://bugs.llvm.org/show_bug.cgi?id=38217
      let c = output - 10000 * (output div 10000)
    else:
      let c = output mod 10000
    output = output div 10000
    let c0 = (c mod 100) shl 1
    let c1 = (c div 100) shl 1
    resul[(result + int32 olength - i - 1) .. (result + int32 olength - i - 1 + 1)] = cast[string](DIGIT_TABLE[c0 .. c0 + 1])
    resul[(result + int32 olength - i - 3) .. (result + int32 olength - i - 3 + 1)] = cast[string](DIGIT_TABLE[c1 .. c1 + 1])
    i += 4
  if output >= 100:
    let c = (output mod 100) shl 1
    output = output div 100
    resul[(result + int32 olength - i - 1) .. (result + int32 olength - i - 1 + 1)] = cast[string](DIGIT_TABLE[c .. c + 1])
    i += 2
  if output >= 10:
    let c = output shl 1
    # We can't use memcpy here: the decimal dot goes between these two digits.
    resul[result + int32 olength - i] = DIGIT_TABLE[c + 1]
    resul[result] = DIGIT_TABLE[c]
  else:
    resul[result] = cast[char](uint32('0') + output)

  # Print decimal point if needed.
  if olength > 1:
    resul[result + 1] = '.'
    result += olength.int32 + 1
  else:
    inc result

  # Print the exponent.
  resul[result] = 'E'
  inc result
  var exp = v.exponent + olength.int32 - 1
  if exp < 0:
    resul[result] = '-'
    inc result
    exp = -exp

  if exp >= 10:
    resul[result .. result + 1] = cast[string](DIGIT_TABLE[2 * exp .. 2 * exp + 1])
    result += 2
  else:
    resul[result] = cast[char](int32('0') + exp)
    inc result

proc f2s*(f: float32): string =
  result.setLen 16

  # Step 1: Decode the floating-point number, and unify normalized and subnormal cases.
  let bits = cast[uint32](f)

  when defined(RYU_DEBUG):
    var temp = "IN="
    for bit in countdown(31, 0):
      temp &= $((bits shr bit) and 1)
    echo temp

  # Decode bits into sign, mantissa, and exponent.
  let ieeeSign = ((bits shr (FLOAT_MANTISSA_BITS + FLOAT_EXPONENT_BITS)) and 1) != 0
  let ieeeMantissa = bits and ((1'u32 shl FLOAT_MANTISSA_BITS) - 1)
  let ieeeExponent = (bits shr FLOAT_MANTISSA_BITS) and ((1'u32 shl FLOAT_EXPONENT_BITS) - 1)

  # Case distinction; exit early for the easy cases.
  result.setLen if ieeeExponent == ((1u shl FLOAT_EXPONENT_BITS) - 1u) or (ieeeExponent == 0 and ieeeMantissa == 0):
                  copy_special_str(result, ieeeSign, ieeeExponent != 0, ieeeMantissa != 0)
                else:
                  to_chars(f2d(ieeeMantissa, ieeeExponent), ieeeSign, result)