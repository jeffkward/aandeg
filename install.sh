#!/usr/bin/env bash
set -euo pipefail

# Aandeg installer — macOS / Apple Silicon only.
# The crow that never leaves home: a private, local AI endpoint.

[ "$(uname -s)" = "Darwin" ] || { echo "Aandeg v1 is macOS only."; exit 1; }
[ "$(uname -m)" = "arm64" ]  || { echo "Aandeg v1 requires Apple Silicon."; exit 1; }

PREFIX="${AANDEG_PREFIX:-$HOME/.aandeg}"
# Guard: never rm -rf into $HOME, / or an empty path (a stray AANDEG_PREFIX).
case "$PREFIX" in
  ""|"/"|"$HOME"|"$HOME/") echo "Refusing to install into '$PREFIX'." >&2; exit 1 ;;
esac
SRC="$(cd "$(dirname "$0")" && pwd)"

# `curl … | bash` pipes only this script, with no repo on disk. If our payload
# (bin/lib/share) isn't sitting next to the script, fetch the repo tarball.
if [ ! -d "$SRC/lib" ]; then
  echo "Downloading Aandeg..."
  _tmp="$(mktemp -d)"
  curl -fsSL https://github.com/jeffkward/aandeg/tarball/main | tar xz -C "$_tmp" || {
    echo "Download failed. Check your connection, or 'git clone' the repo and run 'bash install.sh'." >&2
    exit 1
  }
  SRC="$(echo "$_tmp"/*)"  # GitHub extracts to a single jeffkward-aandeg-<sha>/ dir
fi

echo "Installing Aandeg into $PREFIX ..."
mkdir -p "$PREFIX"
# Clear our own subdirs first so an upgrade never leaves retired files behind.
rm -rf "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/share"
cp -R "$SRC/bin" "$SRC/lib" "$SRC/share" "$PREFIX/"
chmod +x "$PREFIX/bin/aandeg"

# Put `aandeg` on PATH via ~/.local/bin.
mkdir -p "$HOME/.local/bin"
ln -sf "$PREFIX/bin/aandeg" "$HOME/.local/bin/aandeg"
# Guard on the rc file's contents (not the live $PATH), so re-running the
# installer in the same shell doesn't append a duplicate line.
_pathline='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -qF "$_pathline" "$HOME/.zshrc" 2>/dev/null; then
  echo "$_pathline" >> "$HOME/.zshrc"
  echo "Added ~/.local/bin to PATH in ~/.zshrc (open a new terminal to pick it up)."
fi
case "${SHELL:-}" in
  *zsh) ;;
  *) echo "Note: your login shell isn't zsh. Add ~/.local/bin to your shell's PATH so 'aandeg' is found in new terminals." ;;
esac
export PATH="$HOME/.local/bin:$PATH"
export _AANDEG_ROOT="$PREFIX"

# Choose a model from RAM, unless the user forced one. Show the reasoning —
# informed consent: here's what your Mac has, here's what the model needs.
source "$PREFIX/lib/ram.sh"
source "$PREFIX/lib/catalog.sh"
ram="$(aandeg_ram_gb)"
preset="${AANDEG_PRESET:-$(aandeg_recommend_preset "$ram")}"
need="$(aandeg_catalog_field "$preset" needs_gb)"
echo "Your Mac has ${ram}GB of RAM. The best model it can comfortably run is '$preset' ($(aandeg_catalog_field "$preset" model), needs ~${need}GB)."
echo "Prefer something lighter, or want to see the options? Run 'aandeg models' after install."

aandeg use "$preset" --force >/dev/null  # --force: recommend already fits; avoids the guardrail on tiny Macs
echo "Pulling the model and starting the service (first run downloads several GB)..."
aandeg start   # shows the ollama pull progress bar — reassuring during the big download

# Now clear away all that brew/ollama/download noise and show a clean welcome.
aandeg welcome
