import logging
import macros

macro lineinfo(code: untyped): untyped =
  result = newStrLitNode($(code.lineinfo))

template logAllocStats*(level: static[Level], code: untyped) =
  logRunExtra(level):
    let stats1 = getAllocStats()
    block:
      code
    let stats2 = getAllocStats()
    log(level, "[allocStats]", lineinfo(code), $(stats2 - stats1))
  do: 
    code
