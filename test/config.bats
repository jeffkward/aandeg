#!/usr/bin/env bats
setup() {
  export AANDEG_CONFIG="$BATS_TEST_TMPDIR/config"
  source "${BATS_TEST_DIRNAME}/../lib/config.sh"
}

@test "get returns default when unset" {
  [ "$(aandeg_config_get port 11435)" = "11435" ]
}
@test "set then get round-trips" {
  aandeg_config_set preset best
  [ "$(aandeg_config_get preset)" = "best" ]
}
@test "set upserts (no duplicate keys)" {
  aandeg_config_set port 11435
  aandeg_config_set port 12000
  [ "$(aandeg_config_get port)" = "12000" ]
  [ "$(grep -c '^port=' "$AANDEG_CONFIG")" -eq 1 ]
}
@test "config path honors AANDEG_CONFIG override" {
  [ "$(aandeg_config_path)" = "$AANDEG_CONFIG" ]
}
