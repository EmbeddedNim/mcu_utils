
## Any touch ups needed for threads/tasks on embedded platforms 

when defined(zephyr):
  when compileOption("threads"):
    {.emit: """/*INCLUDESECTION*/
    #include <pthread.h>
    """.}
