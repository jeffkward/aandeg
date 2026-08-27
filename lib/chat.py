#!/usr/bin/env python3
"""Aandeg interactive chat — a streaming REPL over the local model.

Reads AANDEG_PORT (default 11435) and, optionally, AANDEG_INITIAL (a first
prompt to send automatically, used by `aandeg -c`). In-memory history only;
Ctrl-D exits, /clear resets the context. Assistant tokens stream to stdout;
all the chrome (banner, prompts, thinking indicator) goes to stderr, so
piping `aandeg chat` still yields clean answers on stdout.
"""
import datetime
import json
import os
import sys
import threading
import urllib.request

try:
    import readline  # noqa: F401 — line editing + history when interactive
except Exception:
    pass

PORT = os.environ.get("AANDEG_PORT", "11435")
BASE = "http://127.0.0.1:%s/v1" % PORT
TTY = sys.stdin.isatty() and sys.stderr.isatty()

GOLD = "\033[38;5;220m" if TTY else ""
GREEN = "\033[32m" if TTY else ""
WHITE = "\033[97m" if TTY else ""
DIM = "\033[2m" if TTY else ""
BOLD = "\033[1m" if TTY else ""
OFF = "\033[0m" if TTY else ""

ART = r"""
        __
     __( o)>   caw.
     \___)

      ___    ___    _   ______  ____________
     /   |  /   |  / | / / __ \/ ____/ ____/
    / /| | / /| | /  |/ / / / / __/ / / __
   / ___ |/ ___ |/ /|  / /_/ / /___/ /_/ /
  /_/  |_/_/  |_/_/ |_/_____/_____/\____/
"""


def err(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def note(msg):
    """A slash-command response, styled like the model's replies: a blank line,
    then a gold dot, so it reads as if the tool answered."""
    if TTY:
        err("\n%s●%s %s\n" % (GOLD, OFF, msg))
    else:
        err("%s\n" % msg)


def resolve_model():
    """Prefer the configured model (AANDEG_MODEL); fall back to whatever the
    server lists first only if that model isn't loaded. Returns None if the
    server is unreachable."""
    want = os.environ.get("AANDEG_MODEL")
    try:
        with urllib.request.urlopen(BASE + "/models", timeout=10) as r:
            ids = [m["id"] for m in json.load(r)["data"]]
    except Exception:
        return None
    if want and want in ids:
        return want
    return ids[0] if ids else None


def _art():
    """The crow + wordmark, loaded from the shared share/aandeg.txt so it never
    drifts from the rest of the tool. Falls back to the baked ART if missing."""
    root = os.environ.get("AANDEG_ROOT", "")
    try:
        with open(os.path.join(root, "share", "aandeg.txt"), encoding="utf-8") as f:
            return "\n" + f.read().rstrip("\n") + "\n"
    except Exception:
        return ART


def banner(model):
    err(GOLD + _art() + OFF)
    err("\n")
    err("  %sA private, local AI, running on your Mac.%s\n" % (WHITE, OFF))
    err("\n")
    err("  %smodel: %s%s\n" % (GREEN, model, OFF))
    err("  %savailable commands: /exit, /clear, /save%s\n" % (GREEN, OFF))


def save_chat(messages, model):
    """Write the whole conversation to a timestamped markdown file in the
    current directory: 2026-08-27-13-14.md, then -2.md, -3.md on repeat."""
    now = datetime.datetime.now()
    stamp = now.strftime("%Y-%m-%d-%H-%M")
    name = stamp + ".md"
    n = 2
    while os.path.exists(name):
        name = "%s-%d.md" % (stamp, n)
        n += 1
    out = ["# Aandeg chat", "", "*%s · %s*" % (now.strftime("%Y-%m-%d %H:%M"), model), ""]
    for m in messages:
        who = "You" if m.get("role") == "user" else "Aandeg"
        out.append("**%s:**" % who)
        out.append("")
        out.append(m.get("content", ""))
        out.append("")
    with open(name, "w", encoding="utf-8") as f:
        f.write("\n".join(out).rstrip() + "\n")
    return name


def stream_reply(messages, model):
    payload = {"model": model, "messages": messages, "stream": True}
    req = urllib.request.Request(
        BASE + "/chat/completions",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"})

    # Animated "thinking... (Ns)" counter until the first token arrives, so a
    # slow first-token (model reload) never looks like a hang. Stderr + TTY only.
    stop = threading.Event()
    if TTY:
        def tick():
            s = 1
            while not stop.wait(1.0):
                if stop.is_set():
                    break
                err("\r%sthinking... (%ds)%s" % (DIM, s, OFF))
                s += 1
        threading.Thread(target=tick, daemon=True).start()

    full = []
    first = True
    try:
        with urllib.request.urlopen(req, timeout=600) as r:
            for raw in r:
                line = raw.decode("utf-8", "replace").strip()
                if not line.startswith("data:"):
                    continue
                data = line[5:].strip()
                if data == "[DONE]":
                    break
                try:
                    delta = json.loads(data)["choices"][0].get("delta", {})
                except Exception:
                    continue
                piece = delta.get("content")
                if piece:
                    if first:
                        stop.set()  # stop the counter before the answer streams
                        if TTY:
                            err("\r\033[K%s●%s " % (GOLD, OFF))  # clear counter, dot before the reply
                        first = False
                    sys.stdout.write(piece)
                    sys.stdout.flush()
                    full.append(piece)
    finally:
        stop.set()  # always stop the counter thread (Ctrl-C propagates to quit)
    if first and TTY:
        err("\r\033[K")
    sys.stdout.write("\n")
    sys.stdout.flush()
    return "".join(full)


def farewell():
    if TTY:
        # Clear the current line first — it may hold a ^C/^D echo the terminal
        # printed, or a partial streamed line — so the exit always reads clean.
        err("\r\033[K\n%s●%s Miigwetch\n\n" % (GOLD, OFF))


def main():
    model = resolve_model()
    if not model:
        err("Aandeg isn't reachable on port %s. Start it with: aandeg start\n" % PORT)
        sys.exit(1)

    # Stop the terminal echoing ^C/^D so quitting reads cleanly.
    fd = old = None
    if sys.stdin.isatty():
        try:
            import termios
            fd = sys.stdin.fileno()
            old = termios.tcgetattr(fd)
            new = termios.tcgetattr(fd)
            new[3] &= ~termios.ECHOCTL  # lflags: don't echo control chars as ^X
            termios.tcsetattr(fd, termios.TCSANOW, new)
        except Exception:
            fd = old = None

    try:
        if TTY:
            err("\033[2J\033[H")  # full-window: clear the screen and home the cursor
            banner(model)

        messages = []
        pending = os.environ.get("AANDEG_INITIAL") or None

        while True:
            if pending is not None:
                text = pending.strip()
                pending = None
                if TTY:
                    err("\n%s❯%s %s\n" % (BOLD, OFF, text))
            else:
                if TTY:
                    err("\n%s❯%s " % (BOLD, OFF))
                try:
                    text = input().strip()
                except EOFError:  # Ctrl-D
                    break
            if not text:
                continue
            if text in ("/exit", "/quit", "exit", "quit"):
                break
            if text == "/clear":
                messages = []
                note("context cleared")
                continue
            if text == "/save":
                try:
                    note("chat saved to %s!" % save_chat(messages, model))
                except Exception as e:
                    note("couldn't save chat: %s" % e)
                continue

            messages.append({"role": "user", "content": text})
            if TTY:
                err("\n")  # blank line between your prompt and the response
            try:
                reply = stream_reply(messages, model)
            except Exception as e:
                err("query failed: %s\n" % e)
                messages.pop()
                continue
            messages.append({"role": "assistant", "content": reply})
    except KeyboardInterrupt:  # Ctrl-C anywhere
        pass
    finally:
        if fd is not None and old is not None:
            try:
                import termios
                termios.tcsetattr(fd, termios.TCSANOW, old)
            except Exception:
                pass
        farewell()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.stderr.write("\n")
        sys.exit(130)
