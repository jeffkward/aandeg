# lib/ollama.sh — obtain Ollama and models. Depends on catalog.sh + service.sh.

aandeg_ollama_ensure() {
  command -v ollama >/dev/null 2>&1 && return 0
  [ -x /opt/homebrew/bin/ollama ] && return 0
  command -v brew >/dev/null 2>&1 || { echo "Homebrew is required. See https://brew.sh"; return 1; }
  brew install ollama
}

# Pull the model for a preset. All catalog sources are Ollama registry tags,
# so the model id IS the pull target.
aandeg_model_ensure() {
  local preset="$1" model source ollama
  model="$(aandeg_catalog_field "$preset" model)"
  source="$(aandeg_catalog_field "$preset" source)"
  ollama="$(aandeg_ollama_bin)"
  # if-form, not `... | grep -qx && return 0`: under `pipefail`, grep -q's
  # early SIGPIPE to the upstream ollama/awk can report the pipeline as failed
  # even on a match, spuriously re-pulling an already-present model.
  if "$ollama" list 2>/dev/null | awk '{print $1}' | grep -qx "$model"; then
    return 0
  fi
  case "$source" in
    registry)
      if ! "$ollama" pull "$model"; then
        echo "Aandeg: couldn't download model '$model'. Check your internet connection and free disk, then rerun 'aandeg start'." >&2
        return 1
      fi ;;
    *) echo "unknown catalog source '$source' for preset '$preset'" >&2; return 1 ;;
  esac
}
