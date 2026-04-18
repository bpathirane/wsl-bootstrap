#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

export DEBIAN_FRONTEND=noninteractive

apt_update_if_stale

BASE_PACKAGES=(
  age bat bison build-essential ca-certificates cifs-utils curl direnv fd-find
  git gnupg htop jq krb5-user libevent-dev lsb-release ncurses-dev pkg-config ripgrep unzip wslu zsh
)

for pkg in "${BASE_PACKAGES[@]}"; do
  apt_install_if_missing "$pkg"
done
