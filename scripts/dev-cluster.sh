#!/usr/bin/env bash
# dev-cluster.sh — One-command soltard dev cluster bringup
# Wraps: clone-and-brand -> build -> genesis -> validator + faucet
#
# Usage: ./scripts/dev-cluster.sh [agave-tag]
#
# STATUS: STUB — Phase 2 implementation pending
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGAVE_TAG="${1:-v2.2.6}"

echo "========================================="
echo " soltard dev-cluster bringup"
echo "========================================="

# TODO: Step 1 — Clone and brand (skip if agave-fork/ exists)
# "${SCRIPT_DIR}/clone-and-brand.sh" "$AGAVE_TAG"

# TODO: Step 2 — Build
# cd "${SCRIPT_DIR}/../agave-fork"
# cargo build --release
# export PATH="${SCRIPT_DIR}/../agave-fork/target/release:${PATH}"

# TODO: Step 3 — Generate genesis
# "${SCRIPT_DIR}/genesis.sh"

# TODO: Step 4 — Start validator + faucet
# "${SCRIPT_DIR}/start-validator.sh"

# TODO: Step 5 — Health check
# "${SCRIPT_DIR}/health-check.sh"

echo ""
echo "[STUB] This script is not yet implemented."
echo "For now, run each step manually:"
echo "  1. ./scripts/clone-and-brand.sh ${AGAVE_TAG}"
echo "  2. cd agave-fork && cargo build --release"
echo "  3. ./scripts/genesis.sh"
echo "  4. ./scripts/start-validator.sh"
