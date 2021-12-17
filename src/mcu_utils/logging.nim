
import strutils
import system

import macros

# from std/logging import Level

# export Level

type
  Level* = enum ## \
    ## Enumeration of logging levels.
    ##
    ## Debug messages represent the lowest logging level, and fatal error
    ## messages represent the highest logging level. ``lvlAll`` can be used
    ## to enable all messages, while ``lvlNone`` can be used to disable all
    ## messages.
    ##
    ## Typical usage for each logging level, from lowest to highest, is
    ## described below:
    ##
    ## * **Debug** - debugging information helpful only to developers
    ## * **Info** - anything associated with normal operation and without
    ##   any particular importance
    ## * **Notice** - more important information that users should be
    ##   notified about
    ## * **Warn** - impending problems that require some attention
    ## * **Error** - error conditions that the application can recover from
    ## * **Fatal** - fatal errors that prevent the application from continuing
    ##
    ## It is completely up to the application how to utilize each level.
    ##
    ## Individual loggers have a ``levelThreshold`` field that filters out
    ## any messages with a level lower than the threshold. There is also
    ## a global filter that applies to all log messages, and it can be changed
    ## using the `setLogFilter proc<#setLogFilter,Level>`_.
    lvlAll,     ## All levels active
    lvlDebug,   ## Debug level and above are active
    lvlInfo,    ## Info level and above are active
    lvlNotice,  ## Notice level and above are active
    lvlWarn,    ## Warn level and above are active
    lvlError,   ## Error level and above are active
    lvlFatal,   ## Fatal level and above are active
    lvlNone     ## No levels active; nothing is logged



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

template logException*(ex: ref Exception, modName: string, lvl: static[Level]) =
  # Log an exception stacktrace piecemeal in order to avoid 
  # large memory usage for big stack traces. These can be upwards
  # of 4kB which can quickly become problematic on small HEAPs
  log(lvl, "[", modName, "]: exception message: ", getCurrentExceptionMsg())
  let stes = getStackTraceEntries(ex)
  for ste in stes:
    log(lvl, "[", modName, "]: exception: ", $ste)

when isMainModule:
  var a = 10

  setLogLevel(lvlDebug)
  logDebug("a: there's bug's?", "never!")
  logWarn("a: warn there's bug's?", "value:", a)

  setLogLevel(lvlInfo)
  logDebug("b: there's bug's?", "never!")
  logInfo("b: info there's bug's?", "value:", a)
  logWarn("b: warn there's bug's?", "value:", a)

