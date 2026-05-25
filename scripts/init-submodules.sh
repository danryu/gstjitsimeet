#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Initializing git submodules (recursive)..."
git submodule update --init --recursive

echo "==> Done. Dependencies are under submodules/"
