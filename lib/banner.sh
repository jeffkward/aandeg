# lib/banner.sh — the shared crow + wordmark, and the post-install welcome
# screen. The ASCII art lives once in share/aandeg.txt (chat.py reads it too).
_AANDEG_ROOT="${_AANDEG_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

aandeg_banner() {
  local gold="" off=""
  [ -t 1 ] && { gold=$'\033[38;5;220m'; off=$'\033[0m'; }
  printf '%s' "$gold"
  cat "$_AANDEG_ROOT/share/aandeg.txt" 2>/dev/null
  printf '%s\n' "$off"
}

# The friendly screen shown at the end of install (and by `aandeg welcome`):
# clear away the scary install output, show the banner, and point at chat.
aandeg_welcome() {
  local white="" green="" dim="" off="" port
  if [ -t 1 ]; then
    white=$'\033[97m'; green=$'\033[32m'; dim=$'\033[2m'; off=$'\033[0m'
    printf '\033[2J\033[H'   # clear the screen
  fi
  port="$(aandeg_config_get port 11435)"
  aandeg_banner
  printf '  %sA private, local AI, running on your Mac.%s\n\n' "$white" "$off"
  printf '  %sYou'\''re all set. Start here:%s\n' "$green" "$off"
  printf '    %saandeg chat%s              talk with it, right now\n' "$white" "$off"
  printf '\n  Other things you can do:\n'
  printf '    aandeg "your question"    a quick one-shot answer\n'
  printf '    aandeg models             see the models and switch\n'
  printf '    aandeg help               everything else\n'
  printf '\n  %sEndpoint for your own apps:%s http://localhost:%s/v1\n' "$dim" "$off" "$port"
  printf '  %sNothing you send it ever leaves this Mac.%s\n\n' "$dim" "$off"
}
