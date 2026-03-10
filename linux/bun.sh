#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if command_exists bun; then
  echo "bun $(bun --version) already installed"
  exit 0
fi

curl -fsSL https://bun.sh/install | bash

echo "bun installed"
