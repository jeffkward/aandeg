# lib/ollama.sh — obtain Ollama and models. Depends on catalog.sh + service.sh.

# Minimum Ollama version that understands the gemma4 architecture. An older
# ollama pulls the model fine but fails to LOAD it (unknown model architecture),
# so we check up front rather than 500 on the first query.
AANDEG_MIN_OLLAMA="0.30.5"

aandeg_ollama_ensure() {
  # Prefer Homebrew's ollama. If it's already there, done. If brew is available,
  # install/use it even when a different (possibly stale) ollama is on PATH —
  # that's how we avoid an old /usr/local/bin/ollama silently winning.
  [ -x /opt/homebrew/bin/ollama ] && return 0
  if command -v brew >/dev/null 2>&1; then
    brew install ollama
    return $?
  fi
  # No Homebrew. Fall back to any ollama already installed (the version check
  # below will catch it if it's too old).
  command -v ollama >/dev/null 2>&1 && return 0
  echo "Homebrew is required to install Ollama. See https://brew.sh" >&2
  return 1
}

# Compare dotted versions: return 0 if $1 >= $2. Pure parameter expansion so it
# works everywhere (bash 3.2, zsh, sh) — no arrays, no `read -a`.
aandeg_ver_ge() {
  local a="$1" b="$2" x y i=0
  while [ "$i" -lt 3 ]; do
    x="${a%%.*}"; [ "$x" = "$a" ] && a="" || a="${a#*.}"
    y="${b%%.*}"; [ "$y" = "$b" ] && b="" || b="${b#*.}"
    x="${x%%[!0-9]*}"; x="${x:-0}"
    y="${y%%[!0-9]*}"; y="${y:-0}"
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
    i=$((i + 1))
  done
  return 0  # equal
}

aandeg_ollama_version() {
  "$(aandeg_ollama_bin)" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# Fail (with a clear message) if the resolved ollama is too old for the model.
aandeg_ollama_check() {
  local v; v="$(aandeg_ollama_version)"
  [ -n "$v" ] || return 0  # can't determine version — don't block
  if ! aandeg_ver_ge "$v" "$AANDEG_MIN_OLLAMA"; then
    echo "Your Ollama ($v) is too old for this model. Update it with: brew install ollama" >&2
    return 1
  fi
  return 0
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
