#!/usr/bin/env bash
# setup-runner.sh — register a self-hosted GitHub Actions runner on the build server
# Run this ONCE on the Dell Precision 7910 (or any Arch build server)
# usage: ./setup-runner.sh <github-token>

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "usage: $0 <github-token>"
    echo ""
    echo "Get a token from: https://github.com/settings/tokens (repo scope)"
    echo "Or use a fine-grained token with Actions:write permission"
    exit 1
fi

TOKEN="$1"
REPO="spivanatalie64/build_acreetionos_iso"
RUNNER_DIR="/opt/actions-runner"

echo "==> Installing runner dependencies..."
sudo pacman -S --noconfirm --needed jq curl

echo "==> Creating runner directory at $RUNNER_DIR..."
sudo mkdir -p "$RUNNER_DIR"
sudo chown "$USER:$USER" "$RUNNER_DIR"
cd "$RUNNER_DIR"

echo "==> Downloading GitHub Actions runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')
curl -o actions-runner-linux-x64.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

echo "==> Extracting runner..."
tar xzf actions-runner-linux-x64.tar.gz

echo "==> Configuring runner..."
./config.sh --url https://github.com/spivanatalie64/build_acreetionos_iso --token "$1" --name "acreetionos-builder" --labels "self-hosted,linux,x64,acreetionos" --unattended

echo "==> Installing as service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "==> Runner registered and running."
echo "    Check status: sudo ./svc.sh status"