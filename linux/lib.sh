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
