#!/usr/bin/env bash
# genesis.sh — Generate soltard genesis block
# Prerequisites: soltard binaries built and in PATH (or use full path)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
LEDGER_DIR="${CONFIG_DIR}/bootstrap-validator-ledger"

mkdir -p "$CONFIG_DIR"

echo "==> Generating keypairs..."
for name in mint validator vote stake faucet; do
    KEYFILE="${CONFIG_DIR}/${name}-keypair.json"
    if [ -f "$KEYFILE" ]; then
        echo "    ${name}-keypair.json already exists, skipping"
    else
        solana-keygen new -o "$KEYFILE" --no-bip39-passphrase --force
        echo "    Created ${name}-keypair.json"
    fi
done

echo "==> Creating genesis block..."
rm -rf "$LEDGER_DIR"

solana-genesis \
    --cluster-type development \
    --ledger "$LEDGER_DIR" \
    --mint "${CONFIG_DIR}/mint-keypair.json" \
    --bootstrap-validator \
        "${CONFIG_DIR}/validator-keypair.json" \
        "${CONFIG_DIR}/vote-keypair.json" \
        "${CONFIG_DIR}/stake-keypair.json" \
    --bootstrap-validator-lamports 500000000000000000 \
    --bootstrap-validator-stake-lamports 1000000000000 \
    --hashes-per-tick auto \
    --faucet-pubkey "${CONFIG_DIR}/faucet-keypair.json" \
    --faucet-lamports 500000000000000000 \
    --slots-per-epoch 432000 \
    --ticks-per-slot 64 \
    --max-genesis-archive-unpacked-size 1073741824

echo "==> Genesis block created at ${LEDGER_DIR}"
echo "    Genesis hash: $(solana-ledger-tool genesis-hash --ledger "$LEDGER_DIR" 2>/dev/null || echo 'run solana-ledger-tool to verify')"
