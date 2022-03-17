import basictypes
export basictypes

converter toHertz*(x: KHertz): Hertz = Hertz(1_000 * x.uint)
converter toHertz*(x: MHertz): Hertz = Hertz(1_000_000 * x.uint)
