#!/usr/bin/env bash
# Downloads the exact tool versions this project uses into ./.tools (Linux x86_64).
# Used by GitHub Actions; also works in any Linux cloud shell.
set -euo pipefail
DEST="${1:-.tools}"
mkdir -p "$DEST"
cd "$DEST"
fetch() { curl -fsSL -o "$1" "$2"; unzip -o -q "$1"; rm -f "$1"; }
[ -x rojo ]   || fetch rojo.zip   https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip
[ -x lune ]   || fetch lune.zip   https://github.com/lune-org/lune/releases/download/v0.8.9/lune-0.8.9-linux-x86_64.zip
[ -x stylua ] || fetch stylua.zip https://github.com/JohnnyMorganz/StyLua/releases/download/v0.20.0/stylua-linux-x86_64.zip
[ -x luau ]   || fetch luau.zip   https://github.com/luau-lang/luau/releases/download/0.640/luau-ubuntu.zip
chmod +x rojo lune stylua luau luau-analyze luau-compile 2>/dev/null || true
echo "Tools ready in $(pwd)"
