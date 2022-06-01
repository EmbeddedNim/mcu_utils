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

proc timerThread(args: ThreadArgs) {.thread.} =
  discard

proc producerThread(args: ThreadArgs) {.thread.} =
  echo "\n===== running producer ===== "
  for i in 1 .. args.count:
    os.sleep(rand(args.tsrand))
    # /* create data item to send */
    var txData = "txNum" & $(1234 + 100 * i)

    # /* send data to consumers */
    echo "-> Producer: tx_data: putting: ", i, " -> ", repr(txData)
    args.queue.send(txData)
    echo "-> Producer: tx_data: sent: ", i

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
    echo fmt"consumer: event: {queueHasDataEvent in events =} "
    withEvent(events, queueHasDataEvent, asKey=readyKey):
      echo fmt"got new data! event: {queueHasDataEvent=} with {readyKey=}"

      var rxData: string
      while queue.tryRecv(rxData):
        inc count
        echo "<- Consumer: rx_data: got: ", count, " <- ", repr(rxData)
    
    echo fmt"{count=} vs {args.count=}"
    if count >= args.count:
      break
    
  echo "Done Consumer "
  echo fmt"queue size: {queue.chan.peek()}"

proc consumerThread(args: ThreadArgs) {.thread.} =
  var queue = args.queue

  echo "\n===== running consumer ===== "
  var selector = newEventSelector()
  selector.registerQueue(queue)
  let defaultTimer = selector.registerTimer(timeout=10, oneshot=true)
  echo fmt"created timer: {defaultTimer=}"

  var events: Table[InetEvent, ReadyKey]

  loop(selector, -1.Millis, events):
    # check specific event
    if defaultTimer in events:
      echo fmt"default timer triggered! "
    
    # print all events
    for evt, key in events:
      echo fmt"event occurred: {evt=} with {key=}"
    
    
  echo "Done Consumer "

proc runTestsChannelThreaded*(ncnt, tsrand: int) =
  echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
  echo "[Channel] Begin "
  randomize()
  var myFifo = InetEventQueue[string].init(4)

  var thrp: Thread[ThreadArgs]
  var thrc: Thread[ThreadArgs]

  createThread(thrc, consumeQueueEvents, ThreadArgs(queue: myFifo, count: ncnt, tsrand: tsrand))
  # os.sleep(2000)
  createThread(thrp, producerThread, ThreadArgs(queue: myFifo, count: ncnt, tsrand: tsrand))
  joinThreads(thrp, thrc)
  echo "[Channel] Done joined "
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "

suite "test for InetQueues functionality":
  echo "suite setup: run once before the tests"
  
  test "timer":
    var cities = @["Cleveland", "Portland"]
    let cityStrings = cities.map do (x:string) -> string:
      "City of " & x
    echo fmt"{cityStrings=}"

  test "faster threaded consumer/producer test":
    runTestsChannelThreaded(11, 100)

  # test "slow threaded consumer/producer test":
    # runTestsChannelThreaded(7, 1200)
