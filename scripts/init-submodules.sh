#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Initializing top-level git submodules..."
git submodule update --init

echo "==> Materializing nested dependencies..."
while IFS=$'\t' read -r path url rev; do
  [[ "$path" == \#* ]] && continue
  [[ -z "${path:-}" ]] && continue
  if [[ ! -e "$path/.git" ]]; then
    echo "    clone $path @ ${rev:0:8}"
    mkdir -p "$(dirname "$path")"
    git clone "$url" "$path"
    git -C "$path" checkout "$rev"
  fi
done < scripts/nested-deps.txt

echo "==> Done."
