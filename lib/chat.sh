# lib/chat.sh — launch the interactive streaming chat REPL (lib/chat.py).
# Depends on config.sh. AANDEG_INITIAL (optional) is inherited from the caller
# — `aandeg -c "..."` sets it to auto-send a first prompt, then continue.

aandeg_chat() {
  local port model
  port="$(aandeg_config_get port 11435)"
  model="$(aandeg_catalog_field "$(aandeg_config_get preset best)" model)"
  AANDEG_PORT="$port" AANDEG_MODEL="$model" AANDEG_ROOT="$_AANDEG_ROOT" python3 "$_AANDEG_ROOT/lib/chat.py"
}
