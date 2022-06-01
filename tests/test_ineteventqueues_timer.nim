import std/os
import std/random
import std/unittest
import sequtils, strformat

import mcu_utils/inetqueues
import mcu_utils/inetselectors

type
  ThreadArgs = object
    queue: InetEventQueue[string]
    count: int
    tsrand: int


## ========================================================= ##
## Produce Queue Events
## 
## ========================================================= ##

proc produceQueueEvents(args: ThreadArgs) {.thread.} =
  echo "\n===== running producer ===== "
  for i in 1 .. args.count:
    os.sleep(rand(args.tsrand))
    # /* create data item to send */
    var txData = "txNum" & $(1234 + 100 * i)

    # /* send data to consumers */
    echo "-> Producer: tx_data: putting: ", i, " -> ", repr(txData)
    args.queue.send(txData, trigger=false)

    if i mod 4 == 0:
      args.queue.trigger()
    echo "-> Producer: tx_data: sent: ", i

  args.queue.trigger()
  echo "Done Producer: "
  
proc consumeQueueEvents(args: ThreadArgs) {.thread.} =
  ## consumer using manual queue events
  ## 
  ## for example if you want to batch multiple items into a queue
  ## then process them in batches
  ## 
  echo "\n===== running consumer ===== "
  var queue = args.queue
  var selector = newEventSelector()
  let queueHasDataEvent = selector.registerQueue(queue)
  echo fmt"{queueHasDataEvent=}"

  var events: Table[InetEvent, ReadyKey]
  var count = 0

  loop(selector, -1.Millis, events):
    echo fmt"<- Consumer: has data event? {queueHasDataEvent in events =} "
    withEvent(events, queueHasDataEvent, asKey=readyKey):
      echo fmt"<- Consumer: got data event: {queueHasDataEvent=} with {readyKey=}"

      var rxData: string
      while queue.tryRecv(rxData):
        inc count
        echo "<- Consumer: rx_data: got: ", count, " <- ", repr(rxData)
    
    if count >= args.count:
      break
    
  echo "Done Consumer "

## ========================================================= ##
## Produce Queue Events
## 
## ========================================================= ##

proc produceTimeEvents(args: ThreadArgs) {.thread.} =
  echo "\n===== running producer ===== "
  var queue = args.queue
  var selector = newEventSelector()
  let queueHasDataEvent = selector.registerQueue(queue)
  echo fmt"{queueHasDataEvent=}"

  var events: Table[InetEvent, ReadyKey]
  var count = 0

  loop(selector, -1.Millis, events):
    os.sleep(rand(args.tsrand))
    # /* create data item to send */
    inc count

    var txData = "txNum" & $(1234 + 100 * count)

    # /* send data to consumers */
    echo "-> Producer: tx_data: putting: ", count, " -> ", repr(txData)
    # var data = isolate(txData)
    let res = args.queue.trySend(txData, trigger=false)
    echo fmt"-> Producer: sent: {res=}"

    # if count mod 4 == 0:
    #   args.queue.trigger()
    echo "-> Producer: tx_data: sent: ", count

  # args.queue.trigger()
  echo "Done Producer: "
  
proc consumeTimeEvents(args: ThreadArgs) {.thread.} =
  ## consumer using manual queue events
  ## 
  ## for example if you want to batch multiple items into a queue
  ## then process them in batches
  ## 
  echo "\n===== running consumer ===== "
  var queue = args.queue
  var selector = newEventSelector()
  let queueHasDataEvent = selector.registerQueue(queue)
  echo fmt"{queueHasDataEvent=}"

  var events: Table[InetEvent, ReadyKey]
  var count = 0

  loop(selector, -1.Millis, events):
    echo fmt"<- Consumer: has data event? {queueHasDataEvent in events =} "
    withEvent(events, queueHasDataEvent, asKey=readyKey):
      echo fmt"<- Consumer: got data event: {queueHasDataEvent=} with {readyKey=}"

      var rxData: string
      while queue.tryRecv(rxData):
        inc count
        echo "<- Consumer: rx_data: got: ", count, " <- ", repr(rxData)
    
    if count >= args.count:
      break
    
  echo "Done Consumer "

proc runTestsThreaded*(ncnt, tsrand: int;
                       consumer, producer: proc (args: ThreadArgs) {.thread.}) =
  echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
  echo "[Channel] Begin "
  var myFifo = InetEventQueue[string].init(4)
  var thrp, thrc: Thread[ThreadArgs]
  createThread(thrc, consumer, ThreadArgs(queue: myFifo, count: ncnt, tsrand: tsrand))
  createThread(thrp, producer, ThreadArgs(queue: myFifo, count: ncnt, tsrand: tsrand))
  joinThreads(thrp, thrc)
  echo "[Channel] Done joined "
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "

suite "test for InetQueues functionality":
  echo "suite setup: run once before the tests"
  randomize()

  test "timer":
    var cities = @["Cleveland", "Portland"]
    let cityStrings = cities.map do (x:string) -> string:
      "City of " & x
    echo fmt"{cityStrings=}"

  test "queue event testing":
    runTestsThreaded(11, 100, consumeQueueEvents, produceQueueEvents)


  test "timer event testing":
    runTestsThreaded(11, 100, produceTimeEvents, consumeTimeEvents)

  # test "slow threaded consumer/producer test":
    # runTestsChannelThreaded(7, 1200)
