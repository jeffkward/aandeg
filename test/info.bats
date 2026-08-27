#!/usr/bin/env bats
setup() {
  export AANDEG_CONFIG="$BATS_TEST_TMPDIR/config"
  source "${BATS_TEST_DIRNAME}/../lib/catalog.sh"
  source "${BATS_TEST_DIRNAME}/../lib/config.sh"
  source "${BATS_TEST_DIRNAME}/../lib/info.sh"
  aandeg_config_set preset best
  aandeg_config_set port 11435
}

@test "manifest names the resolved model" {
  aandeg_info_json | grep -q '"model": "gemma4:26b-a4b-it-qat"'
}
@test "manifest reports the preset" {
  aandeg_info_json | grep -q '"preset": "best"'
}
@test "manifest reports the 256K context window" {
  aandeg_info_json | grep -q '"context_window": 262144'
}
@test "manifest advertises structured output" {
  aandeg_info_json | grep -q '"structured_output": true'
}
@test "manifest modality is a JSON array with vision" {
  aandeg_info_json | grep -q '"modality": \["text","vision"\]'
}
@test "manifest reports native tool-calling" {
  aandeg_info_json | grep -q '"tool_calling": "native"'
}
@test "manifest reports the thinking capability" {
  aandeg_info_json | grep -q '"thinking": true'
}
@test "manifest carries the endpoint with the configured port" {
  aandeg_info_json | grep -q '"endpoint": "http://localhost:11435/v1"'
}
@test "manifest is valid JSON (parses)" {
  aandeg_info_json | python3 -c 'import json,sys; json.load(sys.stdin)'
}
@test "manifest stays valid JSON even for a hand-edited bogus preset" {
  aandeg_config_set preset enormous
  aandeg_info_json | python3 -c 'import json,sys; json.load(sys.stdin)'
}
