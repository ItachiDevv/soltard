#!/usr/bin/env bash
# dev-cluster.sh — Start soltard dev cluster using soltard-test-validator
# Handles genesis, validator, and faucet in a single process
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
LOG_DIR="${CONFIG_DIR}/logs"
PID_DIR="${CONFIG_DIR}/pids"
LEDGER_DIR="${CONFIG_DIR}/test-ledger"
FORK_BIN="${SCRIPT_DIR}/../agave-fork/target/release"

export PATH="${FORK_BIN}:${PATH}"

mkdir -p "$LOG_DIR" "$PID_DIR"

# Verify binary exists
if ! command -v soltard-test-validator &>/dev/null; then
    echo "ERROR: soltard-test-validator not found in PATH or ${FORK_BIN}"
    echo "Run: cd agave-fork && cargo build --release --bin soltard-test-validator"
    exit 1
fi

# Stop any existing cluster
"${SCRIPT_DIR}/stop-cluster.sh" 2>/dev/null || true

echo "========================================="
echo " Starting soltard dev cluster"
echo "========================================="

# Start test-validator (includes built-in faucet, genesis, and RPC)
echo "==> Starting soltard-test-validator..."
soltard-test-validator \
    --reset \
    --ledger "$LEDGER_DIR" \
    --rpc-port 8899 \
    --faucet-port 9900 \
    --log \
    >> "${LOG_DIR}/validator.log" 2>&1 &

VALIDATOR_PID=$!
echo "$VALIDATOR_PID" > "${PID_DIR}/validator.pid"
echo "    Validator PID: ${VALIDATOR_PID}"

# Wait for RPC to become healthy
echo "==> Waiting for RPC to become healthy..."
MAX_WAIT=60
for i in $(seq 1 $MAX_WAIT); do
    sleep 1

    if ! kill -0 "$VALIDATOR_PID" 2>/dev/null; then
        echo "ERROR: Validator exited prematurely."
        echo "Last 30 lines of log:"
        tail -30 "${LOG_DIR}/validator.log" 2>/dev/null || true
        exit 1
    fi

    HEALTH=$(curl -sf http://127.0.0.1:8899 -X POST \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' 2>/dev/null || true)

    if echo "$HEALTH" | grep -q '"ok"'; then
        echo "    RPC is healthy! (after ${i}s)"
        break
    fi

    if [ "$i" -eq "$MAX_WAIT" ]; then
        echo "ERROR: RPC did not become healthy within ${MAX_WAIT}s"
        tail -30 "${LOG_DIR}/validator.log" 2>/dev/null || true
        exit 1
    fi

    printf "    Waiting... (%d/%d)\r" "$i" "$MAX_WAIT"
done

# Print cluster info
echo ""
echo "==> Cluster info:"
HEALTH=$(curl -sf http://127.0.0.1:8899 -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}')
echo "    Health: ${HEALTH}"

SLOT=$(curl -sf http://127.0.0.1:8899 -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}')
echo "    Slot: ${SLOT}"

VERSION=$(curl -sf http://127.0.0.1:8899 -X POST \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"getVersion"}')
echo "    Version: ${VERSION}"

echo ""
echo "========================================="
echo " soltard dev cluster is RUNNING"
echo "========================================="
echo "  RPC:       http://127.0.0.1:8899"
echo "  WS:        ws://127.0.0.1:8900"
echo "  Faucet:    127.0.0.1:9900"
echo "  Validator: PID ${VALIDATOR_PID}"
echo "  Ledger:    ${LEDGER_DIR}"
echo "  Logs:      ${LOG_DIR}/validator.log"
echo "  Stop:      ./scripts/stop-cluster.sh"
echo "========================================="
