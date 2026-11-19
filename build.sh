#!/bin/bash
# Builds "Drop Key.app" from src/DropKey.applescript. macOS only.
set -euo pipefail
cd "$(dirname "$0")"
rm -rf "Drop Key.app"
/usr/bin/osacompile -o "Drop Key.app" src/DropKey.applescript
echo "Built: $(pwd)/Drop Key.app"
echo "Move it to /Applications (or ~/Applications) and double-click to use."
