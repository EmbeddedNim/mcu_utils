import std/posix
import std/nativesockets
import std/os

export SocketHandle

const
  EFD_SEMAPHORE = 0x2.cint

type
  EventCount = uint64

proc eventfd(count: cuint, flags: cint): cint
     {.cdecl, importc: "eventfd", header: "<sys/eventfd.h>".}

proc newEventFd*(init: EventCount, flags: cint): SocketHandle =
  ## Create a new eventfd socket handle. The underlying
  ## file descriptor is mean to be used as a signaling mechanism
  ## that is compatible with POSIX read/writes.  
  ## 
  ## Good for use with `poll` and `select` API's.
  ## 
  let res = eventfd(init.cuint, flags.cint)
  if res < 0:
    raiseOSError(osLastError())
  
  result = SocketHandle(res)

proc newEventFd*(init: EventCount, blocking = true, semaphore = false): SocketHandle =
  ## Create a new eventfd socket handle. Same as previous but with 
  ## options for setting `blocking` and `semaphore`.
  ## 
  var flags: cint = 0
  if not blocking:
    flags = flags or posix.O_NONBLOCK
  if semaphore:
    flags = flags or EFD_SEMAPHORE
  result = newEventFd(init, flags)
