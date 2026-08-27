# lib/config.sh — tiny key=value config store.
# Honors AANDEG_CONFIG override (tests and the installer rely on it).

aandeg_config_path() { printf '%s' "${AANDEG_CONFIG:-$HOME/.config/aandeg/config}"; }

aandeg_config_get() {
  local key="$1" default="${2:-}" path val
  path="$(aandeg_config_path)"
  [ -f "$path" ] || { printf '%s' "$default"; return 0; }
  val="$(grep -E "^${key}=" "$path" | tail -1 | cut -d= -f2-)"
  [ -n "$val" ] && printf '%s' "$val" || printf '%s' "$default"
}

aandeg_config_set() {
  local key="$1" value="$2" path tmp
  path="$(aandeg_config_path)"
  mkdir -p "$(dirname "$path")"; touch "$path"
  if grep -qE "^${key}=" "$path"; then
    tmp="$(mktemp)"
    grep -vE "^${key}=" "$path" > "$tmp" || true; mv "$tmp" "$path"
  fi
  printf '%s=%s\n' "$key" "$value" >> "$path"
}
