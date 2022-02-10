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
    var res: bool
    while not res:
      # this will print txData string
      echo "txData tosend: ", txData
      var item = isolate txData
      echo "txData tosend: ", item, " from: ", txData

      res = channels.trySend(myFifo.chan, item)
      echo "queue full... trying again."
      os.sleep(40)

    # this will print empty string
    echo "txData sent: ", txData

    echo "-> Producer: tx_data: sent: ", i
  echo "Done Producer: "
  
proc consumerThread(args: (InetStrQueue, int, int)) {.thread.} =
  var
    myFifo = args[0]
    count = args[1]
    tsrand = args[2]
  echo "\n===== running consumer ===== "
  var rxData: string
  for i in 0..<count:
    os.sleep(rand(tsrand))
    echo "<- Consumer: rx_data: wait: ", i
    while not myFifo.tryRecv(rxData):
      echo "no data... trying again."
      os.sleep(40)
    echo "<- Consumer: rx_data: got: ", i, " <- ", repr(rxData)

  assert rxData == "txNum1834"
  echo "Done Consumer "

proc runTestsChannelThreaded*(ncnt, tsrand: int) =
  echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
  echo "[Channel] Begin "
  randomize()
  var myFifo = InetStrQueue.init(3)

  var thrp: Thread[(InetStrQueue, int, int)]
  var thrc: Thread[(InetStrQueue, int, int)]

  # os.sleep(2000)
  createThread(thrp, producerThread, (myFifo, ncnt, tsrand))
  createThread(thrc, consumerThread, (myFifo, ncnt, 2*tsrand))
  joinThreads(thrp, thrc)
  echo "[Channel] Done joined "
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "

when isMainModule:
  runTestsChannelThreaded(7, 1200)
