# lib/catalog.sh — the single source of truth for presets, models, their
# advertised capabilities, and how much RAM each needs. Drives `aandeg use`,
# `aandeg models`, `aandeg info`, and the installer's recommendation.
#
# Implemented as a `case` lookup (not an associative array) so it runs on
# macOS's system bash 3.2 as well as modern bash — no version dependency.
#
# Models are Ollama registry tags (pulled with `ollama pull`). All three tags
# (e4b/12b/26b-a4b -it-qat) are confirmed present in the Ollama registry.
# `best`'s capability values are verified from `ollama show gemma4:26b-a4b-it-qat`;
# balanced/small use sound gemma4-family defaults, refined the first time pulled.
#
# Fields: model ctx max_out modality structured tools thinking quant source needs_gb
#   modality: comma-separated list (e.g. "text,vision")
#   tools:    "native" | "none"
#   source:   "registry" (pull the model id) — reserved for future backends
#   needs_gb: approximate RAM the model wants to run comfortably (model + overhead)

aandeg_catalog_field() {
  local preset="$1" field="$2"
  case "$preset.$field" in
    small.model)      printf 'gemma4:e4b-it-qat' ;;
    small.ctx)        printf '32768' ;;
    small.max_out)    printf '4096' ;;
    small.modality)   printf 'text' ;;
    small.structured) printf 'true' ;;
    small.tools)      printf 'none' ;;
    small.thinking)   printf 'false' ;;
    small.quant)      printf 'q4_0' ;;
    small.source)     printf 'registry' ;;
    small.needs_gb)   printf '6' ;;

    balanced.model)      printf 'gemma4:12b-it-qat' ;;
    balanced.ctx)        printf '262144' ;;
    balanced.max_out)    printf '8192' ;;
    balanced.modality)   printf 'text,vision' ;;
    balanced.structured) printf 'true' ;;
    balanced.tools)      printf 'native' ;;
    balanced.thinking)   printf 'true' ;;
    balanced.quant)      printf 'q4_0' ;;
    balanced.source)     printf 'registry' ;;
    balanced.needs_gb)   printf '10' ;;

    best.model)      printf 'gemma4:26b-a4b-it-qat' ;;
    best.ctx)        printf '262144' ;;
    best.max_out)    printf '8192' ;;
    best.modality)   printf 'text,vision' ;;
    best.structured) printf 'true' ;;
    best.tools)      printf 'native' ;;
    best.thinking)   printf 'true' ;;
    best.quant)      printf 'q4_0' ;;
    best.source)     printf 'registry' ;;
    best.needs_gb)   printf '18' ;;

    *) printf '' ;;
  esac
}

# Does this preset's model fit in the given RAM? (exit 0 = fits)
aandeg_preset_fits() {
  local preset="$1" ram="$2" need
  need="$(aandeg_catalog_field "$preset" needs_gb)"
  [ -n "$need" ] && [ "$ram" -ge "$need" ]
}

# The most capable preset that fits the given RAM (best > balanced > small).
# Falls back to small on very small machines so there's always an answer.
aandeg_recommend_preset() {
  local ram="$1" p
  for p in best balanced small; do
    aandeg_preset_fits "$p" "$ram" && { printf '%s' "$p"; return 0; }
  done
  printf 'small'
}
