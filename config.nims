--threads:on

import std/[os, strutils]

task test, "test the integration tests":

  for dtest in listFiles("tests/"):
    if dtest.splitFile()[1].startsWith("t") and dtest.endsWith(".nim"):
      echo("\nTesting: " & $dtest)
      exec("nim c -r " & dtest)
