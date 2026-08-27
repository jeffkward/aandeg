#!/usr/bin/env bats
setup() { source "${BATS_TEST_DIRNAME}/../lib/ram.sh"; }

@test "ram_gb is a positive integer" {
  run aandeg_ram_gb
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [ "$output" -gt 0 ]
}
