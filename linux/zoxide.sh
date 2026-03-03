#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists zoxide; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi
