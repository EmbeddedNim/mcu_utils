
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

# A table of all two-digit numbers. This is used to speed up decimal digit
# generation by copying pairs of digits into the final output.
const DIGIT_TABLE* = [
  '0','0','0','1','0','2','0','3','0','4','0','5','0','6','0','7','0','8','0','9',
  '1','0','1','1','1','2','1','3','1','4','1','5','1','6','1','7','1','8','1','9',
  '2','0','2','1','2','2','2','3','2','4','2','5','2','6','2','7','2','8','2','9',
  '3','0','3','1','3','2','3','3','3','4','3','5','3','6','3','7','3','8','3','9',
  '4','0','4','1','4','2','4','3','4','4','4','5','4','6','4','7','4','8','4','9',
  '5','0','5','1','5','2','5','3','5','4','5','5','5','6','5','7','5','8','5','9',
  '6','0','6','1','6','2','6','3','6','4','6','5','6','6','6','7','6','8','6','9',
  '7','0','7','1','7','2','7','3','7','4','7','5','7','6','7','7','7','8','7','9',
  '8','0','8','1','8','2','8','3','8','4','8','5','8','6','8','7','8','8','8','9',
  '9','0','9','1','9','2','9','3','9','4','9','5','9','6','9','7','9','8','9','9'
]# Copyright 2018 Ulf Adams
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
  return int32(sign) + 3# Copyright 2018 Ulf Adams
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


proc umul128*(a, b: uint64, productHi: var uint64): uint64 {.inline.} =
  # The casts here help MSVC to avoid calls to the __allmul library function.
  let aLo = uint32 a
  let aHi = uint32 a shr 32
  let bLo = uint32 b
  let bHi = uint32 b shr 32

  let b00: uint64 = aLo.uint64 * bLo
  let b01: uint64 = aLo.uint64 * bHi
  let b10: uint64 = aHi.uint64 * bLo
  let b11: uint64 = aHi.uint64 * bHi

  let b00Lo = uint32 b00
  let b00Hi = uint32 b00 shr 32

  let mid1: uint64 = b10 + b00Hi
  let mid1Lo = uint32 mid1
  let mid1Hi = uint32 mid1 shr 32

  let mid2: uint64 = b01 + mid1Lo
  let mid2Lo = uint32 mid2
  let mid2Hi = uint32 mid2 shr 32

  let pHi: uint64 = b11 + mid1Hi + mid2Hi
  let pLo: uint64 = b00Lo or mid2Lo.uint64 shl 32

  productHi = pHi
  return pLo

proc shiftright128*(lo, hi: uint64, dist: uint32): uint64 {.inline.} =
  # We don't need to handle the case dist >= 64 here (see above).
  assert dist < 64
  when defined(RYU_OPTIMIZE_SIZE) or not defined(RYU_32_BIT_PLATFORM):
    assert dist > 0
    (hi shl (64 - dist)) or (lo shr dist)
  else:
    # Avoid a 64-bit shift by taking advantage of the range of shift values.
    assert dist >= 32
    (hi shl (64 - dist)) or uint32(lo shr 32) shr (dist - 32)

proc pow5Factor(value: uint64): uint32 {.inline.} =
  var value = value
  while true:
    assert value != 0
    let q: uint64 = value div 5
    let r: uint32 = value.uint32 - 5 * q.uint32
    if r != 0:
      break
    value = q
    inc result

proc multipleOfPowerOf5*(value: uint64, p: uint32): bool {.inline.} = pow5Factor(value) >= p
  # Returns true if value is divisible by 5^p.
  # I tried a case distinction on p, but there was no performance difference.

proc multipleOfPowerOf2*(value: uint64, p: uint32): bool {.inline.} =
  # Returns true if value is divisible by 2^p.
  assert value != 0
  # __builtin_ctzll doesn't appear to be faster here.
  (value and ((1'u64 shl p) - 1)) == 0

proc mulShiftAll64*(m: uint64, mul: array[2, uint64], j: int32, vp, vm: var uint64, mmShift: uint32): uint64 {.inline.} =
  # This is faster if we don't have a 64x64->128-bit multiplication.
  let m = m shl 1
  # m is maximum 55 bits
  var tmp: uint64
  let lo: uint64 = umul128(m, mul[0], tmp)
  var hi: uint64
  let mid: uint64 = tmp + umul128(m, mul[1], hi)
  hi += uint64(mid < tmp) # overflow into hi

  let lo2: uint64 = lo + mul[0]
  let mid2: uint64 = mid + mul[1] + uint64(lo2 < lo)
  let hi2: uint64 = hi + uint64(mid2 < mid)
  vp = shiftright128(mid2, hi2, uint32(j - 64 - 1))

  if mmShift == 1:
    let lo3: uint64 = lo - mul[0]
    let mid3: uint64 = mid - mul[1] - uint64(lo3 > lo)
    let hi3: uint64 = hi - uint64(mid3 > mid)
    vm = shiftright128(mid3, hi3, uint32(j - 64 - 1))
  else:
    let lo3: uint64 = lo + lo
    let mid3: uint64 = mid + mid + uint64(lo3 < lo)
    let hi3: uint64 = hi + hi + uint64(mid3 < mid)
    let lo4: uint64 = lo3 - mul[0]
    let mid4: uint64 = mid3 - mul[1] - uint64(lo4 > lo3)
    let hi4: uint64 = hi3 - uint64(mid4 > mid3)
    vm = shiftright128(mid4, hi4, uint32(j - 64))

  return shiftright128(mid, hi, uint32(j - 64 - 1))# Copyright 2018 Ulf Adams
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


# These tables are generated by PrintDoubleLookupTable.
const DOUBLE_POW5_INV_BITCOUNT* = 125
const DOUBLE_POW5_BITCOUNT* = 125

const DOUBLE_POW5_INV_SPLIT2: array[13, array[2, uint64]] = [
  [                    1'u64, 2305843009213693952'u64 ],
  [  5955668970331000884'u64, 1784059615882449851'u64 ],
  [  8982663654677661702'u64, 1380349269358112757'u64 ],
  [  7286864317269821294'u64, 2135987035920910082'u64 ],
  [  7005857020398200553'u64, 1652639921975621497'u64 ],
  [ 17965325103354776697'u64, 1278668206209430417'u64 ],
  [  8928596168509315048'u64, 1978643211784836272'u64 ],
  [ 10075671573058298858'u64, 1530901034580419511'u64 ],
  [   597001226353042382'u64, 1184477304306571148'u64 ],
  [  1527430471115325346'u64, 1832889850782397517'u64 ],
  [ 12533209867169019542'u64, 1418129833677084982'u64 ],
  [  5577825024675947042'u64, 2194449627517475473'u64 ],
  [ 11006974540203867551'u64, 1697873161311732311'u64 ]
]
const POW5_INV_OFFSETS: array[19, uint32] = [
  0x54544554'u32, 0x04055545'u32, 0x10041000'u32, 0x00400414'u32, 0x40010000'u32, 0x41155555'u32,
  0x00000454'u32, 0x00010044'u32, 0x40000000'u32, 0x44000041'u32, 0x50454450'u32, 0x55550054'u32,
  0x51655554'u32, 0x40004000'u32, 0x01000001'u32, 0x00010500'u32, 0x51515411'u32, 0x05555554'u32,
  0x00000000'u32
]

const DOUBLE_POW5_SPLIT2: array[13, array[2, uint64]] = [
  [                    0'u64, 1152921504606846976'u64 ],
  [                    0'u64, 1490116119384765625'u64 ],
  [  1032610780636961552'u64, 1925929944387235853'u64 ],
  [  7910200175544436838'u64, 1244603055572228341'u64 ],
  [ 16941905809032713930'u64, 1608611746708759036'u64 ],
  [ 13024893955298202172'u64, 2079081953128979843'u64 ],
  [  6607496772837067824'u64, 1343575221513417750'u64 ],
  [ 17332926989895652603'u64, 1736530273035216783'u64 ],
  [ 13037379183483547984'u64, 2244412773384604712'u64 ],
  [  1605989338741628675'u64, 1450417759929778918'u64 ],
  [  9630225068416591280'u64, 1874621017369538693'u64 ],
  [   665883850346957067'u64, 1211445438634777304'u64 ],
  [ 14931890668723713708'u64, 1565756531257009982'u64 ]
]
const POW5_OFFSETS: array[21, uint32] = [
  0x00000000'u32, 0x00000000'u32, 0x00000000'u32, 0x00000000'u32, 0x40000000'u32, 0x59695995'u32,
  0x55545555'u32, 0x56555515'u32, 0x41150504'u32, 0x40555410'u32, 0x44555145'u32, 0x44504540'u32,
  0x45555550'u32, 0x40004000'u32, 0x96440440'u32, 0x55565565'u32, 0x54454045'u32, 0x40154151'u32,
  0x55559155'u32, 0x51405555'u32, 0x00000105'u32
]

const DOUBLE_POW5_TABLE: array[26, uint64] = [
1'u64, 5'u64, 25'u64, 125'u64, 625'u64, 3125'u64, 15625'u64, 78125'u64, 390625'u64,
1953125'u64, 9765625'u64, 48828125'u64, 244140625'u64, 1220703125'u64, 6103515625'u64,
30517578125'u64, 152587890625'u64, 762939453125'u64, 3814697265625'u64,
19073486328125'u64, 95367431640625'u64, 476837158203125'u64,
2384185791015625'u64, 11920928955078125'u64, 59604644775390625'u64,
298023223876953125'u64 #, 1490116119384765625'u64
]

proc double_computePow5*(i: uint32): array[2, uint64] {.inline.} =
  # Computes 5^i in the form required by Ryu, and stores it in the given pointer.
  let base: uint32 = i div DOUBLE_POW5_TABLE.len
  let base2: uint32 = base * DOUBLE_POW5_TABLE.len
  let offset: uint32 = i - base2
  let mul: array[2, uint64] = DOUBLE_POW5_SPLIT2[base]
  if offset == 0:
    result[0] = mul[0]
    result[1] = mul[1]
    return
  let m: uint64 = DOUBLE_POW5_TABLE[offset]
  var high1: uint64
  let low1: uint64 = umul128(m, mul[1], high1)
  var high0: uint64
  let low0: uint64 = umul128(m, mul[0], high0)
  let sum: uint64 = high0 + low1
  if sum < high0:
    inc high1 # overflow into high1
  # high1 | sum | low0
  let delta: uint32 = uint32 pow5bits(int32 i) - pow5bits(int32 base2)
  result[0] = shiftright128(low0, sum, delta) + ((POW5_OFFSETS[i div 16] shr ((i mod 16) shl 1)) and 3)
  result[1] = shiftright128(sum, high1, delta)

proc double_computeInvPow5*(i: uint32): array[2, uint64] {.inline.} =
  # Computes 5^-i in the form required by Ryu, and stores it in the given pointer.
  let base: uint32 = (i + DOUBLE_POW5_TABLE.len - 1) div DOUBLE_POW5_TABLE.len
  let base2: uint32 = base * DOUBLE_POW5_TABLE.len
  let offset: uint32 = base2 - i
  let mul: array[2, uint64] = DOUBLE_POW5_INV_SPLIT2[base] # 1/5^base2
  if offset == 0:
    result[0] = mul[0]
    result[1] = mul[1]
    return
  let m: uint64 = DOUBLE_POW5_TABLE[offset]
  var high1: uint64
  let low1: uint64 = umul128(m, mul[1], high1)
  var high0: uint64
  let low0: uint64 = umul128(m, mul[0] - 1, high0)
  let sum: uint64 = high0 + low1
  if sum < high0:
    inc high1 # overflow into high1
  # high1 | sum | low0
  let delta: uint32 = uint32 pow5bits(int32 base2) - pow5bits(int32 i)
  result[0] = shiftright128(low0, sum, delta) + 1 + ((POW5_INV_OFFSETS[i div 16] shr ((i mod 16) shl 1)) and 3)
  result[1] = shiftright128(sum, high1, delta)# Copyright 2018 Ulf Adams
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
