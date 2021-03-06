# Package

version       = "0.3.3"
author        = "Jaremy Creechley"
description   = "Utilities and simple helpers for programming with Nim on embedded MCU devices"
license       = "Apache-2.0"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.5"
requires "threading >= 0.1.0"
requires "persistent_enums >= 0.1.0"


task build_integration_tests, "build integration test tools":
  discard # todo: integrations?

after test:
  build_integration_testsTask()
