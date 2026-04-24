#!/usr/bin/env bash
# start-validator.sh — Start soltard bootstrap validator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
LEDGER_DIR="${CONFIG_DIR}/bootstrap-validator-ledger"
LOG_DIR="${CONFIG_DIR}/logs"

mkdir -p "$LOG_DIR"

if [ ! -d "$LEDGER_DIR" ]; then
    echo "ERROR: No ledger found at ${LEDGER_DIR}. Run genesis.sh first."
    exit 1
fi

echo "==> Starting soltard validator..."
solana-validator \
    --identity "${CONFIG_DIR}/validator-keypair.json" \
    --vote-account "${CONFIG_DIR}/vote-keypair.json" \
    --ledger "$LEDGER_DIR" \
    --rpc-port 8899 \
    --rpc-bind-address 0.0.0.0 \
    --gossip-port 8001 \
    --dynamic-port-range 8002-8020 \
    --no-wait-for-vote-to-start-leader \
    --no-os-network-limits-test \
    --enable-rpc-transaction-history \
    --full-rpc-api \
    --log "${LOG_DIR}/validator.log" &

VALIDATOR_PID=$!
echo "    Validator PID: ${VALIDATOR_PID}"

echo "==> Starting faucet..."
solana-faucet \
    --keypair "${CONFIG_DIR}/faucet-keypair.json" \
    --per-time-cap 1000 \
    --per-request-cap 100 &

FAUCET_PID=$!
echo "    Faucet PID: ${FAUCET_PID}"

echo "==> Waiting for validator to initialize..."
sleep 5

echo "==> Configuring CLI..."
solana config set --url http://localhost:8899 --keypair "${CONFIG_DIR}/mint-keypair.json"

echo "==> Health check..."
for i in $(seq 1 10); do
    if solana cluster-version 2>/dev/null; then
        echo "    Cluster is healthy!"
        solana slot
        solana block-height
        break
    fi
    echo "    Waiting... (attempt ${i}/10)"
    sleep 3
done

echo ""
echo "==> Soltard dev cluster is running"
echo "    RPC:    http://localhost:8899"
echo "    WS:     ws://localhost:8900"
echo "    Faucet: localhost:9900"
echo ""
echo "    To stop: kill ${VALIDATOR_PID} ${FAUCET_PID}"
