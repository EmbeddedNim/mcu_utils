
import strutils
import system

import macros

from std/logging import Level

export Level

const
  McuUtilsLoggingLevel* {.strdefine.} = "lvlAll"

var McuUtilsLevel {.compileTime.} = parseEnum[Level](McuUtilsLoggingLevel)

template initLogging*(args: varargs[untyped]) = 
  discard args

macro logImpl(level: static[Level]; msg: string, args: varargs[string, `$`]) =
  let lvl: int = level.ord()
  result = nnkStmtList.newTree()
  echo "LVL: ", lvl, " McuUtilsLevel:", McuUtilsLevel
  if lvl >= ord(McuUtilsLevel):
    for i in countdown(args.len(), 0, 1):
      args.insert(i, newStrLitNode(" "))
    args.insert(0, msg)
    result.add newCall("echo", args[0..^1])

macro setLogLevel*(level: static[Level]) =
  McuUtilsLevel = level

template log*(level: static[Level], msg: string, args: varargs[string, `$`]) = logImpl(lvlDebug, msg, args) 

template logDebug*(msg: string, args: varargs[string, `$`]) = logImpl(lvlDebug, msg, args) 
template logError*(msg: string, args: varargs[string, `$`]) = logImpl(lvlError, msg, args) 
template logFatal*(msg: string, args: varargs[string, `$`]) = logImpl(lvlFatal, msg, args) 
template logInfo*(msg: string, args: varargs[string, `$`]) = logImpl(lvlInfo, msg, args) 
template logWarn*(msg: string, args: varargs[string, `$`]) = logImpl(lvlWarn, msg, args) 
template logNotice*(msg: string, args: varargs[string, `$`]) = logImpl(lvlNotice, msg, args) 

when isMainModule:
  var a = 10

  setLogLevel(lvlDebug)
  logDebug("a: there's bug's?", "never!")
  logWarn("a: warn there's bug's?", "value:", a)

  setLogLevel(lvlInfo)
  logDebug("b: there's bug's?", "never!")
  logInfo("b: info there's bug's?", "value:", a)
  logWarn("b: warn there's bug's?", "value:", a)

