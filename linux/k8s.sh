#!/usr/bin/env bash
set -e
source "$(dirname "$0")/lib.sh"

if ! command_exists kubectl; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

if [ ! -d "/opt/kubectx" ]; then
  sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
  sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kctx
  sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kns
fi

if ! command_exists k9s; then
  curl -sS https://webinstall.dev/k9s | bash
fi

if ! command_exists helm; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
