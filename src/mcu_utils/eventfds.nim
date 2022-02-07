
type
  EventFd = uint64

proc eventfd*(count: cuint, flags: cint): cint
     {.cdecl, importc: "eventfd", header: "<sys/eventfd.h>".}
