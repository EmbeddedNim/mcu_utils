import logging
import macros

macro lineinfo(code: untyped): untyped =
  result = newStrLitNode($(code.lineinfo))


template logAllocStats*(level: static[Level], code: untyped) =
  ## Log allocations that occur during the code block
  ## must pass `-d:nimAllocStats` during compilation
  logRunExtra(level):
    let stats1 = getAllocStats()
    block:
      code
    let stats2 = getAllocStats()
    log(level, "[allocStats]", lineinfo(code), "::", $(stats2 - stats1))
  do: 
    code
