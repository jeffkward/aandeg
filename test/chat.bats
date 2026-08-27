#!/usr/bin/env bats
# The chat REPL is interactive/streaming and is smoke-tested live; here we
# just guard that the script compiles and the CLI advertises the commands.

@test "chat.py compiles" {
  run python3 -c "import py_compile; py_compile.compile('${BATS_TEST_DIRNAME}/../lib/chat.py', doraise=True)"
  [ "$status" -eq 0 ]
}
@test "help lists chat and -c" {
  run bash "${BATS_TEST_DIRNAME}/../bin/aandeg" help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "aandeg chat"
  echo "$output" | grep -q 'aandeg -c'
}
