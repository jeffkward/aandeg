#!/usr/bin/env bats
setup() { source "${BATS_TEST_DIRNAME}/../lib/catalog.sh"; }

@test "best model id (verified via ollama show)" { [ "$(aandeg_catalog_field best model)"    = "gemma4:26b-a4b-it-qat" ]; }
@test "best context is 256K"                     { [ "$(aandeg_catalog_field best ctx)"      = "262144" ]; }
@test "best advertises vision"                   { [ "$(aandeg_catalog_field best modality)" = "text,vision" ]; }
@test "best has native tools"                    { [ "$(aandeg_catalog_field best tools)"    = "native" ]; }
@test "best has a thinking mode"                 { [ "$(aandeg_catalog_field best thinking)" = "true" ]; }
@test "best supports structured output"          { [ "$(aandeg_catalog_field best structured)" = "true" ]; }
@test "best source is the registry tag"          { [ "$(aandeg_catalog_field best source)"   = "registry" ]; }
@test "balanced model id"                        { [ "$(aandeg_catalog_field balanced model)" = "gemma4:12b-it-qat" ]; }
@test "small model id"                           { [ "$(aandeg_catalog_field small model)"    = "gemma4:e4b-it-qat" ]; }
@test "small has no tool-calling"                { [ "$(aandeg_catalog_field small tools)"    = "none" ]; }
@test "unknown field is empty"                   { [ -z "$(aandeg_catalog_field best nope)" ]; }

@test "best needs ~18GB"        { [ "$(aandeg_catalog_field best needs_gb)"  = "18" ]; }
@test "small needs ~6GB"        { [ "$(aandeg_catalog_field small needs_gb)" = "6" ]; }

@test "best fits a 64GB Mac"    { aandeg_preset_fits best 64; }
@test "best does NOT fit 16GB"  { ! aandeg_preset_fits best 16; }
@test "small fits 8GB"          { aandeg_preset_fits small 8; }

@test "recommend: 64GB -> best"     { [ "$(aandeg_recommend_preset 64)" = "best" ]; }
@test "recommend: 16GB -> balanced" { [ "$(aandeg_recommend_preset 16)" = "balanced" ]; }
@test "recommend: 8GB -> small"     { [ "$(aandeg_recommend_preset 8)"  = "small" ]; }
@test "recommend: 4GB -> small (fallback)" { [ "$(aandeg_recommend_preset 4)" = "small" ]; }
