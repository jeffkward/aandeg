# lib/ask.sh — one-shot query to the running model, for quick tests.
# Depends on config.sh. Uses the OpenAI chat API (clean output, no thinking
# spinner) via curl + python3 (python3 is only needed for `aandeg ask`).

# Combine an optional prompt arg with piped stdin into one prompt string.
# arg only -> arg ; stdin only -> stdin ; both -> "arg\n\nstdin" ; neither -> exit 1.
aandeg_compose_prompt() {
  local arg="${1:-}" piped=""
  [ -t 0 ] || piped="$(cat)"
  if   [ -n "$arg" ] && [ -n "$piped" ]; then printf '%s\n\n%s' "$arg" "$piped"
  elif [ -n "$arg" ];   then printf '%s' "$arg"
  elif [ -n "$piped" ]; then printf '%s' "$piped"
  else return 1
  fi
}

# The actual request. Reads MODEL/PORT/PROMPT from the env; prints the answer
# to stdout, or an error to stderr with a nonzero exit.
_aandeg_query() {
  python3 - <<'PY'
import json, os, sys, urllib.request
payload = {"model": os.environ["MODEL"],
           "messages": [{"role": "user", "content": os.environ["PROMPT"]}]}
req = urllib.request.Request(
    "http://127.0.0.1:%s/v1/chat/completions" % os.environ["PORT"],
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"})
try:
    resp = urllib.request.urlopen(req, timeout=300)  # first call reloads the model
    print(json.load(resp)["choices"][0]["message"]["content"])
except Exception as e:
    print("query failed: %s" % e, file=sys.stderr); sys.exit(1)
PY
}

aandeg_ask() {
  local port model prompt out err rc s
  port="$(aandeg_config_get port 11435)"
  prompt="$(aandeg_compose_prompt "${1:-}")" || {
    echo 'usage: aandeg ask "your prompt"   (or pipe content in: some-cmd | aandeg ask "instruction")' >&2
    return 1
  }
  if ! aandeg_health "$port"; then
    echo "Aandeg isn't reachable on port ${port}. Start it with: aandeg start" >&2
    return 1
  fi
  # Use the configured preset's model (what info/use/doctor report), not just
  # whatever /v1/models lists first.
  model="$(aandeg_catalog_field "$(aandeg_config_get preset best)" model)"

  out="$(mktemp)"; err="$(mktemp)"
  MODEL="$model" PORT="$port" PROMPT="$prompt" _aandeg_query >"$out" 2>"$err" &
  local pid=$!
  # Live "thinking..." counter — stderr only, and only for an interactive
  # terminal, so piped/programmatic output (stdout) stays clean.
  if [ -t 2 ]; then
    s=1
    while kill -0 "$pid" 2>/dev/null; do
      printf '\rthinking... (%ds)' "$s" >&2
      sleep 1; s=$((s + 1))
    done
    printf '\r\033[K' >&2   # clear the counter line
  fi
  if wait "$pid"; then rc=0; else rc=$?; fi
  if [ "$rc" -ne 0 ]; then cat "$err" >&2; else cat "$out"; fi
  rm -f "$out" "$err"
  return "$rc"
}
