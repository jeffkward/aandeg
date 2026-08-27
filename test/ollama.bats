#!/usr/bin/env bats
setup() { source "${BATS_TEST_DIRNAME}/../lib/ollama.sh"; }

@test "ver_ge: equal versions"        { aandeg_ver_ge 0.30.5 0.30.5; }
@test "ver_ge: higher patch >= floor" { aandeg_ver_ge 0.33.0 0.30.5; }
@test "ver_ge: higher minor >= floor" { aandeg_ver_ge 0.31.0 0.30.5; }
@test "ver_ge: higher major >= floor" { aandeg_ver_ge 1.0.0  0.30.5; }
@test "ver_ge: old version fails (the 0.24.0 case)" { ! aandeg_ver_ge 0.24.0 0.30.5; }
@test "ver_ge: one patch below fails" { ! aandeg_ver_ge 0.30.4 0.30.5; }
