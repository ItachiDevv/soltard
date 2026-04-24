#!/usr/bin/env bash
# clone-and-brand.sh — Clone agave and apply soltard branding
# Usage: ./scripts/clone-and-brand.sh [agave-tag]
set -euo pipefail

AGAVE_REPO="https://github.com/anza-xyz/agave.git"
AGAVE_TAG="${1:-v2.2.6}"
SOLTARD_DIR="$(cd "$(dirname "$0")/.." && pwd)/agave-fork"

echo "==> Cloning agave ${AGAVE_TAG} into ${SOLTARD_DIR}..."
if [ -d "$SOLTARD_DIR" ]; then
    echo "    Directory exists, skipping clone"
else
    git clone --depth 1 --branch "$AGAVE_TAG" "$AGAVE_REPO" "$SOLTARD_DIR"
fi

cd "$SOLTARD_DIR"

echo "==> Renaming binaries in Cargo.toml files..."
# Rename key binary targets from solana-* to soltard-*
BINS_TO_RENAME=(
    "validator/Cargo.toml:solana-validator:soltard-validator"
    "genesis/Cargo.toml:solana-genesis:soltard-genesis"
    "faucet/Cargo.toml:solana-faucet:soltard-faucet"
    "keygen/Cargo.toml:solana-keygen:soltard-keygen"
    "ledger-tool/Cargo.toml:solana-ledger-tool:soltard-ledger-tool"
    "cli/Cargo.toml:solana:soltard"
)

for entry in "${BINS_TO_RENAME[@]}"; do
    IFS=: read -r file old new <<< "$entry"
    if [ -f "$file" ]; then
        sed -i "s/^name = \"${old}\"/name = \"${new}\"/" "$file"
        echo "    Renamed ${old} -> ${new} in ${file}"
    else
        echo "    WARN: ${file} not found, skipping"
    fi
done

# Handle test-validator separately (nested path)
TV_CARGO="test-validator/Cargo.toml"
if [ -f "$TV_CARGO" ]; then
    sed -i 's/^name = "solana-test-validator"/name = "soltard-test-validator"/' "$TV_CARGO"
    echo "    Renamed solana-test-validator -> soltard-test-validator"
fi

echo "==> Patching version string..."
# Add soltard identifier to version output
VERSION_FILE="cli/src/cli.rs"
if [ -f "$VERSION_FILE" ]; then
    sed -i 's/crate_version!()/concat!(crate_version!(), "-soltard")/' "$VERSION_FILE" 2>/dev/null || true
    echo "    Patched version string"
fi

echo "==> Setting default config directory..."
CONFIG_FILE="cli/src/cli_output/mod.rs"
if [ -f "$CONFIG_FILE" ]; then
    sed -i 's|\.config/solana|.config/soltard|g' "$CONFIG_FILE" 2>/dev/null || true
fi
# Also patch the config path in sdk
find sdk/ -name "*.rs" -exec grep -l '\.config/solana' {} \; 2>/dev/null | head -5 | while read f; do
    sed -i 's|\.config/solana|.config/soltard|g' "$f"
    echo "    Patched config path in $f"
done

echo "==> Done! Soltard branding applied to ${SOLTARD_DIR}"
echo "    Next: cd ${SOLTARD_DIR} && cargo build --release"
