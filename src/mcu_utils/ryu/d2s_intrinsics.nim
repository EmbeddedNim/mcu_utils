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

import common

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

  return shiftright128(mid, hi, uint32(j - 64 - 1))