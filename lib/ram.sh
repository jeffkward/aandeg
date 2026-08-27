# lib/ram.sh — physical RAM detection (macOS).
# Preset recommendation lives in catalog.sh, alongside each model's needs_gb.

aandeg_ram_gb() {
  local bytes
  bytes="$(sysctl -n hw.memsize 2>/dev/null)" || return 1
  echo $(( bytes / 1073741824 ))
}
