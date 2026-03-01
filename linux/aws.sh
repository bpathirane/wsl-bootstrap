#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists aws; then
  curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
fi
