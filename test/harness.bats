#!/usr/bin/env bats

@test "harness runs" {
  run bash -c 'echo hello'
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}
