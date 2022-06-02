import std/json
import basictypes
export basictypes

type
  TimeSML* = distinct float64 ##\
    ## Represents SenML formatted time (f64). 
    ## 
    ## Values less than 268,435,456 (2**28) represent time relative to the
    ## current time.  That is, a time of zero indicates that the sensor does
    ## not know the absolute time and the measurement was made roughly
    ## "now".  A negative value indicates seconds in the past from roughly
    ## "now".  Positive values up to 2**28 indicate seconds in the future
    ## from "now".  An example for employing positive values would be
    ## actuation use, when the desired change should happen in the future,
    ## but the sender or the receiver does not have accurate time available.


proc `+`*(a, b: TimeSML): TimeSML {.borrow.}
proc `-`*(a, b: TimeSML): TimeSML {.borrow.}
proc `%`*(a: TimeSML): JsonNode {.borrow.}

when defined(zephyr):
  import nephyr/times
  export millis
  export micros
elif defined(arduino):
  proc arduinoMillis(): culong {.importc: "$1", header: "<Arduino.h>".}
  proc millis*(): Millis = Millis(cast[int64](arduinoMillis()))
else:
  import std/[times, monotimes]
  proc millis*(): Millis = 
    let ts = getMonoTime()
    result = Millis(convert(Nanoseconds, Milliseconds, ts.ticks))
  proc micros*(): Micros = 
    let ts = getMonoTime()
    result = Micros(convert(Nanoseconds, Microseconds, ts.ticks))

proc currTimeSenML*(): TimeSML =
  let mt = getMonoTime()
  var micros = 1.0e-6 * convert(Nanoseconds, Microseconds, mt.ticks).toBiggestFloat()
  result = TimeSML(micros)

proc timeSenML*(ms: Millis): TimeSML =
  var msf = 1.0e-3 * ms.int64.toBiggestFloat()
  result = TimeSML(msf)

proc timeSenML*(us: Micros): TimeSML =
  var usf = 1.0e-6 * us.int64.toBiggestFloat()
  result = TimeSML(usf)
