#!/usr/bin/env bats
setup() { source "${BATS_TEST_DIRNAME}/../lib/service.sh"; }

@test "plist render substitutes the port" {
  run aandeg_plist_render 11435 30
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "127.0.0.1:11435"
}
@test "plist render substitutes keep-alive minutes" {
  aandeg_plist_render 11435 45 | grep -q "OLLAMA_KEEP_ALIVE"
  aandeg_plist_render 11435 45 | grep -q "<string>45m</string>"
}
@test "plist carries the service label" {
  aandeg_plist_render 11435 30 | grep -q "com.aandeg.server"
}
@test "plist render leaves no unsubstituted placeholders" {
  ! aandeg_plist_render 11435 30 | grep -q "__"
}
