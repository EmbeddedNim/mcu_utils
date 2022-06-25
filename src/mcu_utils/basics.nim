import bitops

import basictypes
export basictypes

converter toHertz*(x: KHertz): Hertz = Hertz(1_000 * x.uint)
converter toHertz*(x: MHertz): Hertz = Hertz(1_000_000 * x.uint)

template setBits*[T: SomeInteger, V](b: var T, slice: Slice[int], x: V) = 
  b.clearMask(slice)
  b.setMask(T(x) shl slice.a)
