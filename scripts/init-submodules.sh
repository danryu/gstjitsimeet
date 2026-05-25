#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Initializing top-level git submodules..."
git submodule update --init --recursive

materialize_nested() {
  local dir="$1"
  local txt="$dir/submodules.txt"
  [[ -f "$txt" ]] || return 0

  while read -r name url rev; do
    [[ -n "${name:-}" ]] || continue
    local target="$dir/submodules/$name"
    if [[ ! -e "$target/.git" ]]; then
      echo "==> Cloning nested dependency $target"
      mkdir -p "$(dirname "$target")"
      git clone "$url" "$target"
      git -C "$target" checkout "$rev"
    fi
    materialize_nested "$target"
  done < "$txt"
}

echo "==> Materializing nested dependencies from submodules.txt..."
materialize_nested "."
materialize_nested "submodules/libjitsimeet"

echo "==> Done."
