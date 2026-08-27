# lib/service.sh — launchd plist rendering + (un)load, and a health check.
_AANDEG_ROOT="${_AANDEG_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
_AANDEG_PLIST="$HOME/Library/LaunchAgents/com.aandeg.server.plist"

aandeg_ollama_bin() {
  # Prefer the Homebrew ollama (what our installer sets up, and current enough
  # for recent model architectures). A stale ollama elsewhere on PATH (e.g. an
  # old /usr/local/bin/ollama) must not win, or new models fail to load.
  for p in /opt/homebrew/bin/ollama /opt/homebrew/opt/ollama/bin/ollama; do
    [ -x "$p" ] && { echo "$p"; return; }
  done
  command -v ollama 2>/dev/null || echo /opt/homebrew/bin/ollama
}

aandeg_plist_render() {
  local port="$1" idle="$2" ollama
  ollama="$(aandeg_ollama_bin)"
  sed -e "s|__PORT__|$port|g" -e "s|__KEEPALIVE__|$idle|g" -e "s|__OLLAMA__|$ollama|g" \
    "$_AANDEG_ROOT/share/com.aandeg.server.plist.template"
}

aandeg_service_install() {
  mkdir -p "$(dirname "$_AANDEG_PLIST")"
  aandeg_plist_render "$1" "$2" > "$_AANDEG_PLIST"
}

aandeg_service_load()   { launchctl unload "$_AANDEG_PLIST" 2>/dev/null || true; launchctl load "$_AANDEG_PLIST"; }
aandeg_service_unload() { launchctl unload "$_AANDEG_PLIST" 2>/dev/null || true; }
aandeg_health()         { curl -fs "http://127.0.0.1:${1}/api/version" >/dev/null 2>&1; }
