# lib/info.sh — build the machine-facing capabilities manifest.
# Depends on catalog.sh + config.sh already being sourced.

# Turn a comma list ("text,vision") into JSON array elements ("text","vision").
_aandeg_modality_json() {
  local csv="$1" out="" part
  local IFS=,
  for part in $csv; do
    out="${out:+$out,}\"$part\""
  done
  printf '[%s]' "$out"
}

aandeg_info_json() {
  local preset port idle model ctx maxout modality structured tools thinking quant
  preset="$(aandeg_config_get preset best)"
  port="$(aandeg_config_get port 11435)"
  idle="$(aandeg_config_get idle_timeout 30)"
  model="$(aandeg_catalog_field "$preset" model)"
  ctx="$(aandeg_catalog_field "$preset" ctx)"
  maxout="$(aandeg_catalog_field "$preset" max_out)"
  modality="$(_aandeg_modality_json "$(aandeg_catalog_field "$preset" modality)")"
  structured="$(aandeg_catalog_field "$preset" structured)"
  tools="$(aandeg_catalog_field "$preset" tools)"
  thinking="$(aandeg_catalog_field "$preset" thinking)"
  quant="$(aandeg_catalog_field "$preset" quant)"
  # If the config was hand-edited to an unknown preset, the catalog returns
  # empty strings — default the numerics/bools so the output stays valid JSON.
  model="${model:-unknown}"; ctx="${ctx:-0}"; maxout="${maxout:-0}"
  structured="${structured:-false}"; thinking="${thinking:-false}"; idle="${idle:-30}"
  cat <<JSON
{
  "preset": "$preset",
  "model": "$model",
  "context_window": $ctx,
  "max_output_tokens": $maxout,
  "modality": $modality,
  "structured_output": $structured,
  "tool_calling": "$tools",
  "thinking": $thinking,
  "quant": "$quant",
  "endpoint": "http://localhost:$port/v1",
  "keep_alive_minutes": $idle
}
JSON
}
