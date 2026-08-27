#!/usr/bin/env bats
# Pure prompt-composition tests (no network). The actual query path is
# smoke-tested live, not here.
ASK="${BATS_TEST_DIRNAME}/../lib/ask.sh"

@test "compose: arg only (no stdin)" {
  run bash -c "source '$ASK'; aandeg_compose_prompt 'hello there' </dev/null"
  [ "$status" -eq 0 ]
  [ "$output" = "hello there" ]
}
@test "compose: stdin only" {
  run bash -c "source '$ASK'; printf 'piped content' | aandeg_compose_prompt ''"
  [ "$status" -eq 0 ]
  [ "$output" = "piped content" ]
}
@test "compose: arg + stdin are combined" {
  run bash -c "source '$ASK'; printf 'the body' | aandeg_compose_prompt 'summarize:'"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "summarize:"
  echo "$output" | grep -q "the body"
}
@test "compose: nothing at all -> nonzero" {
  run bash -c "source '$ASK'; aandeg_compose_prompt '' </dev/null"
  [ "$status" -ne 0 ]
}
