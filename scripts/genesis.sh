#!/usr/bin/env bash
# genesis.sh — Generate soltard genesis block
# Sources config/genesis-params.env for tunable parameters
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
PARAMS_FILE="${CONFIG_DIR}/genesis-params.env"
LEDGER_DIR="${CONFIG_DIR}/bootstrap-validator-ledger"

# Load genesis parameters
if [ -f "$PARAMS_FILE" ]; then
    # shellcheck disable=SC1090
    source "$PARAMS_FILE"
    echo "==> Loaded genesis params from ${PARAMS_FILE}"
else
    echo "WARN: ${PARAMS_FILE} not found, using defaults"
fi

# Defaults (if not set by params file)
SOLTARD_CLUSTER_TYPE="${SOLTARD_CLUSTER_TYPE:-development}"
SOLTARD_VALIDATOR_LAMPORTS="${SOLTARD_VALIDATOR_LAMPORTS:-500000000000000000}"
SOLTARD_VALIDATOR_STAKE="${SOLTARD_VALIDATOR_STAKE:-1000000000000}"
SOLTARD_FAUCET_LAMPORTS="${SOLTARD_FAUCET_LAMPORTS:-500000000000000000}"
SOLTARD_SLOTS_PER_EPOCH="${SOLTARD_SLOTS_PER_EPOCH:-432000}"
SOLTARD_TICKS_PER_SLOT="${SOLTARD_TICKS_PER_SLOT:-64}"
SOLTARD_HASHES_PER_TICK="${SOLTARD_HASHES_PER_TICK:-auto}"
SOLTARD_MAX_GENESIS_ARCHIVE="${SOLTARD_MAX_GENESIS_ARCHIVE:-1073741824}"

# Detect binary names (prefer built soltard-* from agave-fork, fallback to PATH)
FORK_BIN="${SCRIPT_DIR}/../agave-fork/target/release"
KEYGEN="${FORK_BIN}/soltard-keygen"
GENESIS="${FORK_BIN}/soltard-genesis"
LEDGER_TOOL="${FORK_BIN}/soltard-ledger-tool"
if [ ! -x "$KEYGEN" ]; then
    KEYGEN="$(command -v soltard-keygen 2>/dev/null || command -v solana-keygen 2>/dev/null || echo solana-keygen)"
    GENESIS="$(command -v soltard-genesis 2>/dev/null || command -v solana-genesis 2>/dev/null || echo solana-genesis)"
    LEDGER_TOOL="$(command -v soltard-ledger-tool 2>/dev/null || command -v solana-ledger-tool 2>/dev/null || echo solana-ledger-tool)"
fi

mkdir -p "$CONFIG_DIR"

echo "==> Generating keypairs..."
for name in mint validator vote stake faucet; do
    KEYFILE="${CONFIG_DIR}/${name}-keypair.json"
    if [ -f "$KEYFILE" ]; then
        echo "    ${name}-keypair.json exists, skipping"
    else
        $KEYGEN new -o "$KEYFILE" --no-bip39-passphrase --force
        echo "    Created ${name}-keypair.json"
    fi
done

echo "==> Creating genesis block..."
echo "    Cluster type: ${SOLTARD_CLUSTER_TYPE}"
echo "    Validator lamports: ${SOLTARD_VALIDATOR_LAMPORTS}"
echo "    Faucet lamports: ${SOLTARD_FAUCET_LAMPORTS}"
echo "    Slots/epoch: ${SOLTARD_SLOTS_PER_EPOCH}"

rm -rf "$LEDGER_DIR"

$GENESIS \
    --cluster-type "$SOLTARD_CLUSTER_TYPE" \
    --ledger "$LEDGER_DIR" \
    --bootstrap-validator \
        "${CONFIG_DIR}/validator-keypair.json" \
        "${CONFIG_DIR}/vote-keypair.json" \
        "${CONFIG_DIR}/stake-keypair.json" \
    --bootstrap-validator-lamports "$SOLTARD_VALIDATOR_LAMPORTS" \
    --bootstrap-validator-stake-lamports "$SOLTARD_VALIDATOR_STAKE" \
    --hashes-per-tick "$SOLTARD_HASHES_PER_TICK" \
    --faucet-pubkey "${CONFIG_DIR}/faucet-keypair.json" \
    --faucet-lamports "$SOLTARD_FAUCET_LAMPORTS" \
    --slots-per-epoch "$SOLTARD_SLOTS_PER_EPOCH" \
    --ticks-per-slot "$SOLTARD_TICKS_PER_SLOT" \
    --max-genesis-archive-unpacked-size "$SOLTARD_MAX_GENESIS_ARCHIVE"

echo "==> Genesis block created at ${LEDGER_DIR}"
GENESIS_HASH=$($LEDGER_TOOL genesis-hash --ledger "$LEDGER_DIR" 2>/dev/null || echo "(build soltard-ledger-tool to verify)")
echo "    Genesis hash: ${GENESIS_HASH}"
