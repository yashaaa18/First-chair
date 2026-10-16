#!/usr/bin/env bash
# One command to check, test, build and bake the game.
#   scripts/build.sh            -> build/FirstChair.rbxlx
# Set TOOLS=/path/to/tools if rojo/lune/luau/stylua aren't on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."
TOOLS="${TOOLS:-.tools}"
if [ -d "$TOOLS" ]; then export PATH="$(cd "$TOOLS" && pwd):$PATH"; fi

echo "== 1/5 Formatting (StyLua)"
stylua --check src tests scripts

echo "== 2/5 Logic tests (Luau)"
luau tests/run.luau

echo "== 3/5 Build place file (Rojo)"
mkdir -p build
rojo build default.project.json -o build/FirstChair.rbxlx

echo "== 4/5 Bake the world into the place (Lune)"
lune run scripts/bake.luau build/FirstChair.rbxlx

echo "== 5/5 Headless playthrough of all three cases (Lune)"
lune run scripts/simulate.luau build/FirstChair.rbxlx

echo "Done: build/FirstChair.rbxlx"
