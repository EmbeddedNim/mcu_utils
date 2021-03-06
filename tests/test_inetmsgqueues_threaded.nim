import std/os
import std/random

import mcu_utils/inetqueues

proc producerThread(args: (InetMsgQueue, int, int)) {.thread.} =
  var
    myFifo = args[0]
    count = args[1]
    tsrand = args[2]
  echo "\n===== running producer ===== "
  for i in 0..<count:
    os.sleep(rand(tsrand))
    # /* create data item to send */
    var txData = newQMsgBuffer("txNum" & $(1234 + 100 * i))

    # /* send data to consumers */
    echo "-> Producer: tx_data: putting: ", i, " -> ", repr(txData)
    myFifo.sendMsg(InetClientHandle.empty(), txData)
    echo "-> Producer: tx_data: sent: ", i
  echo "Done Producer: "
  
proc consumerThread(args: (InetMsgQueue, int, int)) {.thread.} =
  var
    myFifo = args[0]
    count = args[1]
    tsrand = args[2]
  echo "\n===== running consumer ===== "
  var lastData: string
  for i in 0..<count:
    os.sleep(rand(tsrand))
    echo "<- Consumer: rx_data: wait: ", i
    var item: InetMsgQueueItem = myFifo.recvMsg()
    let rxData = move item.data
    echo "<- Consumer: rx_data: got: ", i, " <- ", repr(rxData)
    lastData = rxData[].data

  assert lastData == "txNum1834"

  echo "Done Consumer "

proc runTestsChannelThreaded*(ncnt, tsrand: int) =
  echo "\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
  echo "[Channel] Begin "
  randomize()
  var myFifo = InetMsgQueue.init(10)

  var thrp: Thread[(InetMsgQueue, int, int)]
  var thrc: Thread[(InetMsgQueue, int, int)]

  createThread(thrc, consumerThread, (myFifo, ncnt, tsrand))
  # os.sleep(2000)
  createThread(thrp, producerThread, (myFifo, ncnt, tsrand))
  joinThreads(thrp, thrc)
  echo "[Channel] Done joined "
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "

when isMainModule:
  runTestsChannelThreaded(7, 1200)
