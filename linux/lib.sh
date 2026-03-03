#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

apt_install_if_missing() {
  if ! dpkg -s "$1" >/dev/null 2>&1; then
    sudo apt install -y "$1"
  fi
}

ensure_directory() {
  mkdir -p "$1"
}

apt_update_if_stale() {
  local stamp="/var/lib/apt/periodic/update-success-stamp"
  local max_age=3600  # 1 hour in seconds
  if [ -f "$stamp" ]; then
    local last_update
    last_update=$(stat -c %Y "$stamp")
    local now
    now=$(date +%s)
    if (( now - last_update < max_age )); then
      echo "apt cache is fresh (< 1 hour old), skipping update"
      return 0
    fi
  fi
  sudo apt update
}
