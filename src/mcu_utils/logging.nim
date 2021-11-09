
import strutils
import system

import macros

from std/logging import Level

export Level

const
  McuUtilsLoggingLevel* {.strdefine.} = "lvlAll"
  mcuUtilsLevel = parseEnum[Level](McuUtilsLoggingLevel)

template initLogging*(args: varargs[untyped]) = 
  discard args

macro logImpl(level: static[Level]; msg: string, args: varargs[string, `$`]) =
  let lvl: int = level.ord()
  if lvl >= ord(mcuUtilsLevel):
    # result = nnkStmtList.newTree()
    # let v = args.mapIt(newCall("$", it))
    result.add newCall("echo", msg, args)

template log*(level: static[Level], msg: string, args: varargs[string, `$`]) = logImpl(lvlDebug, msg, args) 

template logDebug*(msg: string, args: varargs[string, `$`]) = logImpl(lvlDebug, msg, args) 
template logError*(msg: string, args: varargs[string, `$`]) = logImpl(lvlError, msg, args) 
template logFatal*(msg: string, args: varargs[string, `$`]) = logImpl(lvlFatal, msg, args) 
template logInfo*(msg: string, args: varargs[string, `$`]) = logImpl(lvlInfo, msg, args) 
template logWarn*(msg: string, args: varargs[string, `$`]) = logImpl(lvlWarn, msg, args) 
template logNotice*(msg: string, args: varargs[string, `$`]) = logImpl(lvlNotice, msg, args) 

