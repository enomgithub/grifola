# Package

version       = "0.1.0"
author        = "Satoshi Enomoto"
description   = "Simple image viewer"
license       = "MIT"
srcDir        = "src"
bin           = @["grifola"]


# Dependencies

requires "nim >= 1.6.8"
requires "nigui >= 0.2.6"
requires "pixie >= 5.0.5"


# Tasks

task release, "release build":
  let command = "nimble build -d:release --mm:orc"
  exec command