#!/usr/bin/env bats
# Regression: the installer symlinks bin/aandeg into ~/.local/bin, so the CLI
# must resolve its lib/ root through the symlink even with no _AANDEG_ROOT set.

@test "resolves libs when invoked via a symlink (no _AANDEG_ROOT)" {
  ln -s "${BATS_TEST_DIRNAME}/../bin/aandeg" "$BATS_TEST_TMPDIR/aandeg"
  run env -u _AANDEG_ROOT AANDEG_CONFIG="$BATS_TEST_TMPDIR/config" bash "$BATS_TEST_TMPDIR/aandeg" endpoint
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "http://localhost:11435/v1"
}
