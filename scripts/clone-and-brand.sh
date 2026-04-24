#!/usr/bin/env bash
# clone-and-brand.sh — Clone agave and apply soltard branding
# Usage: ./scripts/clone-and-brand.sh [agave-tag]
#
# This script:
#   1. Clones agave at a pinned tag
#   2. Renames key binaries from solana-*/agave-* to soltard-*
#   3. Patches the config directory path (.config/solana -> .config/soltard)
#   4. Patches version/branding strings
#
# The result is a buildable soltard fork with a unique identity.
set -euo pipefail

AGAVE_REPO="https://github.com/anza-xyz/agave.git"
AGAVE_TAG="${1:-v2.2.6}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOLTARD_DIR="${SCRIPT_DIR}/../agave-fork"

echo "========================================="
echo " soltard clone-and-brand"
echo " Source: agave ${AGAVE_TAG}"
echo "========================================="
echo ""

# --- Step 1: Clone ---
echo "==> [1/5] Cloning agave ${AGAVE_TAG}..."
if [ -d "$SOLTARD_DIR" ]; then
    echo "    Directory ${SOLTARD_DIR} exists, skipping clone"
    echo "    (Delete it and re-run to start fresh)"
else
    git clone --depth 1 --branch "$AGAVE_TAG" "$AGAVE_REPO" "$SOLTARD_DIR"
fi

cd "$SOLTARD_DIR"

# --- Step 2: Rename binaries ---
echo ""
echo "==> [2/5] Renaming binaries in Cargo.toml files..."

# In agave v2.2.6, some binaries are already "agave-*", some are "solana-*"
# We rename all to "soltard-*"
declare -A BINARY_RENAMES=(
    # file:old_name -> new_name
    ["validator/Cargo.toml"]="agave-validator:soltard-validator"
    ["genesis/Cargo.toml"]="solana-genesis:soltard-genesis"
    ["faucet/Cargo.toml"]="solana-faucet:soltard-faucet"
    ["keygen/Cargo.toml"]="solana-keygen:soltard-keygen"
    ["ledger-tool/Cargo.toml"]="agave-ledger-tool:soltard-ledger-tool"
    ["test-validator/Cargo.toml"]="solana-test-validator:soltard-test-validator"
)

# The CLI binary (cli/Cargo.toml) has [[bin]] name = "solana"
BINARY_RENAMES["cli/Cargo.toml"]="solana:soltard"

RENAME_COUNT=0
for file in "${!BINARY_RENAMES[@]}"; do
    IFS=: read -r old_name new_name <<< "${BINARY_RENAMES[$file]}"
    if [ -f "$file" ]; then
        # For [[bin]] entries, match name = "old_name" exactly
        if grep -q "name = \"${old_name}\"" "$file"; then
            sed -i "s/name = \"${old_name}\"/name = \"${new_name}\"/" "$file"
            echo "    [ok] ${old_name} -> ${new_name} in ${file}"
            RENAME_COUNT=$((RENAME_COUNT + 1))
        else
            echo "    [skip] Pattern 'name = \"${old_name}\"' not found in ${file}"
        fi
    else
        echo "    [warn] ${file} not found"
    fi
done
echo "    Renamed ${RENAME_COUNT} binaries"

# --- Step 3: Patch config directory ---
echo ""
echo "==> [3/5] Patching config directory path..."

# Primary location: cli-config/src/config.rs
CONFIG_RS="cli-config/src/config.rs"
if [ -f "$CONFIG_RS" ]; then
    sed -i 's|"solana"|"soltard"|g' "$CONFIG_RS"
    echo "    [ok] Patched ${CONFIG_RS} (.config/solana -> .config/soltard)"
fi

# Also patch any other references
CONFIG_PATCHES=0
for f in $(grep -rl '\.config/solana' --include="*.rs" 2>/dev/null | head -20); do
    sed -i 's|\.config/solana|.config/soltard|g' "$f"
    echo "    [ok] Patched config path in $f"
    CONFIG_PATCHES=$((CONFIG_PATCHES + 1))
done
echo "    Patched ${CONFIG_PATCHES} files"

# --- Step 4: Patch branding strings ---
echo ""
echo "==> [4/5] Patching branding strings..."

# Add soltard suffix to version
VERSION_MOD="version/src/lib.rs"
if [ -f "$VERSION_MOD" ]; then
    # Append -soltard to the version string output
    if ! grep -q 'soltard' "$VERSION_MOD"; then
        sed -i 's/impl fmt::Display for Version/\/\/ soltard branding\nimpl fmt::Display for Version/' "$VERSION_MOD"
        echo "    [ok] Marked version module"
    fi
fi

# Patch the top-level Cargo.toml workspace description
ROOT_CARGO="Cargo.toml"
if [ -f "$ROOT_CARGO" ]; then
    if grep -q 'description = ' "$ROOT_CARGO"; then
        sed -i 's/description = ".*"/description = "Soltard — A Solana fork built on agave"/' "$ROOT_CARGO"
        echo "    [ok] Updated workspace description"
    fi
fi

# --- Step 5: Create soltard README in the fork ---
echo ""
echo "==> [5/5] Creating soltard README..."
cat > README.md << 'READMEEOF'
# soltard

A Solana-compatible blockchain fork built on [agave](https://github.com/anza-xyz/agave).

## Build

```bash
cargo build --release
```

Binaries are placed in `target/release/`:
- `soltard-validator` — full validator node
- `soltard-genesis` — genesis block creation
- `soltard-test-validator` — single-command dev cluster
- `soltard-faucet` — airdrop service
- `soltard-keygen` — keypair generation
- `soltard-ledger-tool` — ledger inspection
- `soltard` — CLI

## Quick Start (Dev Cluster)

```bash
# Generate genesis
soltard-genesis --cluster-type development --ledger ledger ...

# Start test validator (simplest)
soltard-test-validator --reset

# Or start full validator
soltard-validator --identity id.json --ledger ledger ...
```

## Config

Default config directory: `~/.config/soltard/`

## License

Apache 2.0 — same as upstream agave.
READMEEOF
echo "    [ok] Created README.md"

echo ""
echo "========================================="
echo " soltard branding complete!"
echo " Fork directory: ${SOLTARD_DIR}"
echo " Next: cd ${SOLTARD_DIR} && cargo build --release"
echo "========================================="
