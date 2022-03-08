import basictypes
export basictypes

when defined(zephyr):
  proc k_uptime_get(): int64 {.importc: "$1", header: "<kernel.h>".}
  proc millis*(): Millis = Millis(k_uptime_get())
elif defined(arduino):
  proc arduinoMillis(): culong {.importc: "$1", header: "<Arduino.h>".}
  proc millis*(): Millis = Millis(cast[int64](arduinoMillis()))
else:
  proc millis*(): Millis = 
    raise newException(OSError, "millis unimplemented")
