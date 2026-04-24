#!/usr/bin/env bash
# report-status.sh — Poll soltard RPC and write status to Supabase
# Designed to run as a cron job (every 60s)
# Requires: SOLTARD_SUPABASE_URL, SOLTARD_SUPABASE_SERVICE_KEY in ~/.itachi-api-keys

# Source env keys before strict mode (file may reference unset vars)
source ~/.itachi-api-keys 2>/dev/null || true

set -eo pipefail

RPC_URL="${SOLTARD_RPC_URL:-http://127.0.0.1:8899}"
SUPABASE_URL="${SOLTARD_SUPABASE_URL:-}"
SUPABASE_KEY="${SOLTARD_SUPABASE_SERVICE_KEY:-}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo "ERROR: SOLTARD_SUPABASE_URL and SOLTARD_SUPABASE_SERVICE_KEY must be set"
    exit 1
fi

rpc_call() {
    curl -sf "$RPC_URL" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\"}" 2>/dev/null || echo "{}"
}

# Query RPC endpoints
HEALTH_RESP=$(rpc_call "getHealth")
SLOT_RESP=$(rpc_call "getSlot")
BLOCK_RESP=$(rpc_call "getBlockHeight")
EPOCH_RESP=$(rpc_call "getEpochInfo")
VERSION_RESP=$(rpc_call "getVersion")

# Parse responses
IS_HEALTHY=$(echo "$HEALTH_RESP" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print('true' if d.get('result')=='ok' else 'false')
except: print('false')
" 2>/dev/null)

SLOT=$(echo "$SLOT_RESP" | python3 -c "
import sys,json
try: print(json.load(sys.stdin).get('result',0))
except: print(0)
" 2>/dev/null)

BLOCK_HEIGHT=$(echo "$BLOCK_RESP" | python3 -c "
import sys,json
try: print(json.load(sys.stdin).get('result',0))
except: print(0)
" 2>/dev/null)

read -r EPOCH EPOCH_SLOT <<< "$(echo "$EPOCH_RESP" | python3 -c "
import sys,json
try:
    r=json.load(sys.stdin)['result']
    print(r.get('epoch',0), r.get('slotIndex',0))
except: print('0 0')
" 2>/dev/null)"

VERSION=$(echo "$VERSION_RESP" | python3 -c "
import sys,json
try: print(json.load(sys.stdin)['result']['solana-core'])
except: print('unknown')
" 2>/dev/null)

# Ensure cluster_info row exists (upsert by cluster_name)
CLUSTER_ID=$(curl -sf "${SUPABASE_URL}/rest/v1/cluster_info?cluster_name=eq.soltard-dev&select=id" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" | \
    python3 -c "
import sys,json
data=json.load(sys.stdin)
print(data[0]['id'] if data else '')
" 2>/dev/null)

if [ -z "$CLUSTER_ID" ]; then
    CLUSTER_ID=$(curl -sf "${SUPABASE_URL}/rest/v1/cluster_info" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{\"cluster_name\":\"soltard-dev\",\"rpc_url\":\"${RPC_URL}\",\"cluster_type\":\"development\"}" | \
        python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)
    echo "Created cluster_info row: ${CLUSTER_ID}"
fi

# Update cluster_info timestamp
curl -sf "${SUPABASE_URL}/rest/v1/cluster_info?id=eq.${CLUSTER_ID}" \
    -X PATCH \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"updated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > /dev/null 2>&1

# Insert validator_status row
curl -sf "${SUPABASE_URL}/rest/v1/validator_status" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{
        \"cluster_id\": \"${CLUSTER_ID}\",
        \"slot\": ${SLOT},
        \"block_height\": ${BLOCK_HEIGHT},
        \"epoch\": ${EPOCH},
        \"epoch_slot\": ${EPOCH_SLOT},
        \"version\": \"${VERSION}\",
        \"is_healthy\": ${IS_HEALTHY}
    }" > /dev/null 2>&1

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | slot=${SLOT} block=${BLOCK_HEIGHT} epoch=${EPOCH} healthy=${IS_HEALTHY} version=${VERSION}"

# Track epoch transitions
LAST_EPOCH=$(curl -sf "${SUPABASE_URL}/rest/v1/epoch_history?cluster_id=eq.${CLUSTER_ID}&order=epoch.desc&limit=1&select=epoch" \
    -H "apikey: ${SUPABASE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_KEY}" | \
    python3 -c "
import sys,json
data=json.load(sys.stdin)
print(data[0]['epoch'] if data else -1)
" 2>/dev/null)

if [ "$LAST_EPOCH" != "$EPOCH" ]; then
    curl -sf "${SUPABASE_URL}/rest/v1/epoch_history" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "{
            \"cluster_id\": \"${CLUSTER_ID}\",
            \"epoch\": ${EPOCH},
            \"start_slot\": ${SLOT},
            \"started_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
        }" > /dev/null 2>&1
    echo "    New epoch ${EPOCH} recorded"
fi
