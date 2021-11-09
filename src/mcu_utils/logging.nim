
import strutils
import system
import sequtils

import macros

from std/logging import Level

export Level

const
  McuUtilsLoggingLevel* {.strdefine.} = "lvlAll"
  mcuUtilsLevel = parseEnum[Level](McuUtilsLoggingLevel)

template initLogging*(args: varargs[untyped]) = 
  discard args

macro logImpl(level: static[Level]; args: varargs[string, `$`]) =
  let lvl: int = level.ord()
  if lvl >= ord(mcuUtilsLevel):
    # result = nnkStmtList.newTree()
    # let v = args.mapIt(newCall("$", it))
    result.add newCall("echo", args)

template log*(level: static[Level], args: varargs[string, `$`]) = logImpl(lvlDebug, args) 

template debug*(args: varargs[string, `$`]) = logImpl(lvlDebug, args) 
template error*(args: varargs[string, `$`]) = logImpl(lvlError, args) 
template fatal*(args: varargs[string, `$`]) = logImpl(lvlFatal, args) 
template info*(args: varargs[string, `$`]) = logImpl(lvlInfo, args) 
template warn*(args: varargs[string, `$`]) = logImpl(lvlWarn, args) 
template notice*(args: varargs[string, `$`]) = logImpl(lvlNotice, args) 

