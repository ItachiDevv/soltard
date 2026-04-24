#!/usr/bin/env bash
# stop-cluster.sh — Graceful shutdown of soltard dev cluster
#
# STATUS: STUB — Phase 2 implementation pending
set -euo pipefail

echo "==> Stopping soltard cluster..."

# TODO: Implement graceful shutdown
# - Find validator PID (from pidfile or process name)
# - Send SIGTERM, wait, then SIGKILL if needed
# - Stop faucet
# - Clean up PID files

# pkill -f soltard-validator 2>/dev/null || true
# pkill -f soltard-faucet 2>/dev/null || true
# pkill -f solana-validator 2>/dev/null || true
# pkill -f solana-faucet 2>/dev/null || true

echo "[STUB] Stop cluster not yet implemented."
echo "Manual: pkill -f 'soltard-validator|solana-validator'"
