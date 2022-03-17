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

proc currTimeSML*(): TimeSML =
  var ms = 1.0e-3 * millis().int64.toBiggestFloat()
  var us = 1.0e-6 * micros().int64.toBiggestFloat()
  result = TimeSML(ms + us)

proc timeSenML*(ms: Millis, us: Micros): TimeSML =
  var msf = 1.0e-3 * ms.int64.toBiggestFloat()
  var usf = 1.0e-6 * us.int64.toBiggestFloat()
  result = TimeSML(msf + usf)
