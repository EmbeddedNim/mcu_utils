import std/os
import std/random

import mcu_utils/inetqueues

type
  InetStrQueue = InetEventQueue[string]

proc producerThread(args: (InetStrQueue, int, int)) {.thread.} =
  var
    myFifo = args[0]
    count = args[1]
    tsrand = args[2]
  echo "\n===== running producer ===== "
  for i in 0..<count:
    os.sleep(rand(tsrand))
    # /* create data item to send */
    var txData = "txNum" & $(1234 + 100 * i)

    # /* send data to consumers */
    echo "-> Producer: tx_data: putting: ", i, " -> ", repr(txData)
    while not myFifo.trySend(txData):
      echo "queue full... trying again."
    echo "-> Producer: tx_data: sent: ", i
  echo "Done Producer: "
  
proc consumerThread(args: (InetStrQueue, int, int)) {.thread.} =
  var
    myFifo = args[0]
    count = args[1]
    tsrand = args[2]
  echo "\n===== running consumer ===== "
  for i in 0..<count:
    os.sleep(rand(tsrand))
    echo "<- Consumer: rx_data: wait: ", i
    var rxData: string
    while not myFifo.tryRecv(rxData):
      echo "no data... trying again."
    echo "<- Consumer: rx_data: got: ", i, " <- ", repr(rxData)

  echo "Done Consumer "

proc runTestsChannel*() =
  randomize()
  var myFifo = InetStrQueue.init(10)


  producerThread((myFifo, 10, 100))
  consumerThread((myFifo, 10, 100))

proc runTestsChannelThreaded*(ncnt, tsrand: int) =
  echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
  echo "[Channel] Begin "
  randomize()
  var myFifo = InetStrQueue.init(3)

  var thrp: Thread[(InetStrQueue, int, int)]
  var thrc: Thread[(InetStrQueue, int, int)]

  createThread(thrc, consumerThread, (myFifo, ncnt, tsrand))
  # os.sleep(2000)
  createThread(thrp, producerThread, (myFifo, ncnt, tsrand))
  joinThreads(thrp, thrc)
  echo "[Channel] Done joined "
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "

when isMainModule:
  runTestsChannelThreaded(100, 120)
  runTestsChannelThreaded(7, 1200)
