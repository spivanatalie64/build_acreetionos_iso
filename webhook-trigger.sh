#!/usr/bin/env bash
# webhook-trigger.sh — lightweight webhook server that triggers builds
# Listens for GitHub webhook POSTs from acreetionos-code repos and triggers
# a build via repository_dispatch or by running build-all.sh directly.
#
# usage:
#   ./webhook-trigger.sh              # start HTTP listener on :8080
#   ./webhook-trigger.sh --port 9090  # custom port
#   ./webhook-trigger.sh --oneshot    # run once (for cron/scheduled use)

set -euo pipefail

PORT=8080
SECRET="${WEBHOOK_SECRET:-}"
REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --secret) SECRET="$2"; shift 2 ;;
        --oneshot)
            echo "==> Running build once..."
            cd "$REPO_DIR"
            git pull --ff-only
            chmod +x build-all.sh test-iso.sh
            ./build-all.sh
            exit $?
            ;;
        *) echo "unknown: $1"; exit 1 ;;
    esac
done

echo "==> Starting webhook listener on port $PORT..."
while true; do
    REQUEST=$(nc -l -p "$PORT" -q 1 2>/dev/null || true)
    if echo "$REQUEST" | grep -qi "x-github-event: push"; then
        echo "==> Push event received, triggering build..."
        cd "$(dirname "$(readlink -f "$0")")"
        git pull --ff-only
        chmod +x build-all.sh test-iso.sh
        ./build-all.sh
    fi
done