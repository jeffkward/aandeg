# Aandeg

*Aandeg is the Anishinaabemowin word for crow.*

**A private, local AI endpoint for your Mac.** One command installs it, and you get an OpenAI-compatible API running entirely on your own machine. Nothing you send it ever goes to a cloud provider.

Built to make local AI approachable, with no GGUF, quant levels, or parameter counts to learn. Aandeg tells you what each model needs, shows you what your Mac has, and picks the best one that fits. You stay in control; it just keeps you from choosing something your machine can't run.

## Quick Install

Run this in the Terminal app on an Apple Silicon Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/jeffkward/aandeg/main/install.sh | bash
```

### Manual Install

1. `git clone` this repo anywhere
2. Run `bash install.sh`

## Installer Steps

The installer sets up [Ollama](https://ollama.com) if it isn't already there, reads your Mac's RAM, and picks the most capable model that comfortably fits, telling you the reasoning ("your Mac has 64GB; the best model it can run is *best*, which needs ~18GB"). It downloads that model (several GB the first time), installs `aandeg` in `~/.local/bin`, and starts a background service (`com.aandeg.server`) that survives reboots. The model unloads itself after 30 idle minutes, so it costs no memory while you work and reloads on the next request.

Nothing to remember to start. Just point an app at the endpoint, or ask it something:

```bash
aandeg "say hi in one line"
echo "long article text..." | aandeg ask "summarize in 3 bullets"
```

The first request after an idle period takes a few seconds to reload the model (you'll see a `thinking…` counter). After that it's quick.

## Chat

Want a conversation instead of one-shot answers? Start an interactive session:

```bash
aandeg chat
```

```
      __
   __( o)>   caw.
   \___)

    ___    ___    _   ______  ____________
   /   |  /   |  / | / / __ \/ ____/ ____/
  / /| | / /| | /  |/ / / / / __/ / / __
 / ___ |/ ___ |/ /|  / /_/ / /___/ /_/ /
/_/  |_/_/  |_/_/ |_/_____/_____/\____/

  a private, local AI, running on your Mac
```

Replies stream as they're written, and the conversation remembers itself, so you can pull on a thread:

```
you › name three animals
aandeg › 1. Lion  2. Elephant  3. Dolphin

you › tell me more about the second one
aandeg › Elephants are the largest land animals on Earth...
```

`Ctrl-D` (or `/exit`) quits, `/clear` resets the context, and `/save` writes the whole conversation to a timestamped markdown file. Already got an answer from a one-shot and want to keep going? Use `-c`:

```bash
aandeg -c "name three animals"
```

It answers, then drops you straight into chat with that exchange in context. It's a private ChatGPT in your terminal: no account, no cloud, works offline, free to run.

## Choosing a Model: Informed Consent (With Guardrails)

Aandeg auto-picks on install, but you can see the options and switch anytime:

```bash
aandeg models
```

```
Your Mac has 64GB of RAM. Here's what Aandeg can run:

  PRESET    MODEL                  NEEDS   ON YOUR MAC
  small     gemma4:e4b-it-qat      ~6GB    fits
  balanced  gemma4:12b-it-qat      ~10GB   fits
  best      gemma4:26b-a4b-it-qat  ~18GB   fits  <- best your Mac can run (current)
```

- Want a lighter, faster-loading model? `aandeg use small` (or `balanced`) is always allowed.
- Ask for one bigger than your RAM and Aandeg stops you, explains why, and suggests the right fit. You can still override with `aandeg use <preset> --force` if you know what you're doing.

## Commands

```
aandeg chat                 start an interactive streaming chat (Ctrl-D to exit)
aandeg -c "your prompt"     ask, then continue in chat
aandeg ask "your prompt"    one-shot ask (or pipe: some-cmd | aandeg ask "instruction")
aandeg "your prompt"        shortcut for `ask`
aandeg models               list models, the RAM each needs, and why one is recommended
aandeg use <preset>         switch model: small | balanced | best
aandeg start | stop | restart | status | logs
aandeg endpoint             print the base URL to paste into any app
aandeg info                 capabilities manifest (JSON) for programs
aandeg doctor               health check
```

## Point Your App Here

Aandeg serves the standard OpenAI API, so most clients and SDKs work by just changing the base URL. No API key is needed for a local server.

```
Base URL:  http://localhost:11435/v1
```

Learn what's running three ways: `GET /v1/models` for the id, `POST /v1/chat/completions` (and `/v1/completions`) exactly as with OpenAI, and `aandeg info` for the full capabilities manifest a program needs:

```json
{
  "preset": "best",
  "model": "gemma4:26b-a4b-it-qat",
  "context_window": 262144,
  "max_output_tokens": 8192,
  "modality": ["text","vision"],
  "structured_output": true,
  "tool_calling": "native",
  "thinking": true,
  "quant": "q4_0",
  "endpoint": "http://localhost:11435/v1",
  "keep_alive_minutes": 30
}
```

Because the manifest and the model picker read the same catalog, `aandeg info` always describes whatever model is actually loaded.

### Examples

**Drop-in for the OpenAI SDK.** Most tools work by just pointing at the base URL. No key is needed, so pass any placeholder:

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:11435/v1", api_key="local")
resp = client.chat.completions.create(
    model="gemma4:26b-a4b-it-qat",
    messages=[{"role": "user", "content": "Say hi in one line."}],
)
print(resp.choices[0].message.content)
```

**Extract structured data** from messy text with a JSON schema:

```bash
curl -s http://localhost:11435/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "gemma4:26b-a4b-it-qat",
    "messages": [{"role":"user","content":"Pull the vendor, date, and total: \"Blue Mountain Cafe, Aug 27 2026, Total: $18.40\""}],
    "response_format": {"type":"json_schema","json_schema":{"name":"receipt","schema":{
      "type":"object",
      "properties":{"vendor":{"type":"string"},"date":{"type":"string"},"total":{"type":"number"}},
      "required":["vendor","date","total"]}}}
  }'
```

**Stream** the reply token by token (Server-Sent Events), the same thing `aandeg chat` does:

```bash
curl -N -s http://localhost:11435/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "gemma4:26b-a4b-it-qat",
    "stream": true,
    "messages": [{"role":"user","content":"Write a haiku about a crow."}]
  }'
```

## A Note on Data Sovereignty

Aandeg runs the model on your machine and nothing it does sends your text anywhere. But sovereignty is only as real as where you point your requests: **only the calls you send to your Aandeg endpoint are local.** If an app also calls a cloud model, those calls are not private. Aandeg makes the local option easy; it can't make your other tools local.

## Configuration

`~/.config/aandeg/config` (see [`config.sample`](config.sample)):

```
preset=best
port=11435
idle_timeout=30
```

## Scope

Right now only macOS on Apple Silicon. Ollama already runs on Linux and Windows; the installer and launchd service are the macOS-specific parts, so other platforms are a natural next step.

## License

MIT. See [LICENSE](LICENSE).
