#!/usr/bin/env bash
# health-check.sh — Verify soltard cluster is healthy and slots are advancing
# Usage: ./scripts/health-check.sh [rpc-url] [min-slot-advance] [wait-seconds]
set -euo pipefail

RPC_URL="${1:-http://127.0.0.1:8899}"
MIN_ADVANCE="${2:-5}"
WAIT_SECONDS="${3:-30}"

rpc_call() {
    curl -sf "$RPC_URL" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\"}" 2>/dev/null
}

extract_result() {
    echo "$1" | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])" 2>/dev/null
}

echo "========================================="
echo " soltard health check"
echo " RPC: ${RPC_URL}"
echo "========================================="

# Check basic health
echo ""
echo "==> [1/3] Checking getHealth..."
HEALTH_RESP=$(rpc_call "getHealth")
if echo "$HEALTH_RESP" | grep -q '"ok"'; then
    echo "    PASS: getHealth returned \"ok\""
else
    echo "    FAIL: getHealth returned: ${HEALTH_RESP}"
    exit 1
fi

# Get initial slot
echo ""
echo "==> [2/3] Recording initial slot..."
SLOT1_RESP=$(rpc_call "getSlot")
SLOT1=$(extract_result "$SLOT1_RESP")
echo "    Initial slot: ${SLOT1}"

# Get version and epoch info
VERSION_RESP=$(rpc_call "getVersion")
EPOCH_RESP=$(rpc_call "getEpochInfo")
BLOCK_RESP=$(rpc_call "getBlockHeight")
BLOCK_HEIGHT=$(extract_result "$BLOCK_RESP")

echo "    Block height: ${BLOCK_HEIGHT}"
echo "    Version: ${VERSION_RESP}"
echo "    Epoch info: ${EPOCH_RESP}"

# Wait and check slot advancement
echo ""
echo "==> [3/3] Waiting ${WAIT_SECONDS}s to verify slot advancement (need +${MIN_ADVANCE})..."
sleep "$WAIT_SECONDS"

SLOT2_RESP=$(rpc_call "getSlot")
SLOT2=$(extract_result "$SLOT2_RESP")
ADVANCE=$((SLOT2 - SLOT1))

echo "    Final slot: ${SLOT2}"
echo "    Slots advanced: ${ADVANCE} (minimum: ${MIN_ADVANCE})"

if [ "$ADVANCE" -ge "$MIN_ADVANCE" ]; then
    echo ""
    echo "========================================="
    echo " HEALTH CHECK PASSED"
    echo "   Cluster is healthy"
    echo "   Slots advancing: ${ADVANCE} in ${WAIT_SECONDS}s"
    echo "   Block height: ${BLOCK_HEIGHT}"
    echo "========================================="
    exit 0
else
    echo ""
    echo "========================================="
    echo " HEALTH CHECK FAILED"
    echo "   Slots only advanced ${ADVANCE} (need ${MIN_ADVANCE})"
    echo "========================================="
    exit 1
fi
