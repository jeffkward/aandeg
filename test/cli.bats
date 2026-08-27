#!/usr/bin/env bats
setup() {
  export AANDEG_CONFIG="$BATS_TEST_TMPDIR/config"
  export _AANDEG_ROOT="${BATS_TEST_DIRNAME}/.."
  CLI="${BATS_TEST_DIRNAME}/../bin/aandeg"
  bash "$CLI" use best >/dev/null
}

@test "endpoint prints the base url" {
  run bash "$CLI" endpoint
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "http://localhost:11435/v1"
}
@test "info emits the manifest naming the model" {
  run bash "$CLI" info --json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"model": "gemma4:26b-a4b-it-qat"'
}
@test "use writes the preset to config" {
  bash "$CLI" use small
  run bash "$CLI" info
  echo "$output" | grep -q '"preset": "small"'
}
@test "use rejects an unknown preset" {
  run bash "$CLI" use enormous
  [ "$status" -ne 0 ]
}
@test "models lists the presets with RAM needs" {
  run bash "$CLI" models
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "gemma4:26b-a4b-it-qat"
  echo "$output" | grep -q "NEEDS"
}
@test "ask with no prompt and no stdin shows usage and fails (no network)" {
  run bash -c "AANDEG_CONFIG='$AANDEG_CONFIG' _AANDEG_ROOT='$_AANDEG_ROOT' bash '$CLI' ask </dev/null"
  [ "$status" -ne 0 ]
}
@test "help exits zero" {
  run bash "$CLI" help
  [ "$status" -eq 0 ]
}
@test "welcome shows the banner and points at chat + endpoint" {
  run bash "$CLI" welcome
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "aandeg chat"
  echo "$output" | grep -q "http://localhost:11435/v1"
}
