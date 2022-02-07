import std/nativesockets
import std/os

export SocketHandle

type
  EventCount = uint64

proc eventfd(count: cuint, flags: cint): cint
     {.cdecl, importc: "eventfd", header: "<sys/eventfd.h>".}

proc newEventFd*(init: EventCount, flags: int): SocketHandle =
  let res = eventfd(init.cuint, flags.cint)
  if res < 0:
    raiseOSError(osLastError())
  
  result = SocketHandle(res)
