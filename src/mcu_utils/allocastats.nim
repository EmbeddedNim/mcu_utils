import logging

template logAllocStats*(level: static[Level], code: untyped) =
  let stats1 = getAllocStats()
  block:
    code
  let stats2 = getAllocStats()
  logImpl(level, "[allocStats]", $(stats2 - stats1))
