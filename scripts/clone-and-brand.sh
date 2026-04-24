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
# IMPORTANT: Only [[bin]] names are changed. [package] names stay intact
# to avoid breaking workspace dependency resolution.
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
echo "==> [2/5] Renaming binary names (keeping crate/package names intact)..."

RENAME_COUNT=0

# Group A: Crates WITH explicit [[bin]] sections — only rename inside [[bin]]
# These have [package] name != [[bin]] name or same name but separate entry
declare -A BIN_SECTION_RENAMES=(
    ["faucet/Cargo.toml"]="solana-faucet:soltard-faucet"
    ["genesis/Cargo.toml"]="solana-genesis:soltard-genesis"
    ["keygen/Cargo.toml"]="solana-keygen:soltard-keygen"
    ["cli/Cargo.toml"]="solana:soltard"
)

for file in "${!BIN_SECTION_RENAMES[@]}"; do
    IFS=: read -r old_name new_name <<< "${BIN_SECTION_RENAMES[$file]}"
    if [ -f "$file" ]; then
        python3 -c "
import re, sys
with open('$file') as f:
    content = f.read()
# Split on [[bin]] markers to only modify bin sections
parts = re.split(r'(\[\[bin\]\])', content)
changed = False
for i, part in enumerate(parts):
    if part == '[[bin]]' and i+1 < len(parts):
        old = 'name = \"${old_name}\"'
        new = 'name = \"${new_name}\"'
        if old in parts[i+1]:
            parts[i+1] = parts[i+1].replace(old, new, 1)
            changed = True
if changed:
    with open('$file', 'w') as f:
        f.write(''.join(parts))
    sys.exit(0)
sys.exit(1)
" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "    [ok] [[bin]] ${old_name} -> ${new_name} in ${file}"
            RENAME_COUNT=$((RENAME_COUNT + 1))
        else
            echo "    [skip] No [[bin]] name = \"${old_name}\" in ${file}"
        fi
    else
        echo "    [warn] ${file} not found"
    fi
done

# Group B: Crates WITHOUT [[bin]] sections — binary name = package name
# Add explicit [[bin]] sections with new names and disable auto-discovery

# validator crate has 2 binaries: agave-validator (main.rs) + solana-test-validator (src/bin/)
VALIDATOR_TOML="validator/Cargo.toml"
if [ -f "$VALIDATOR_TOML" ] && ! grep -q '\[\[bin\]\]' "$VALIDATOR_TOML"; then
    # Add autobins = false under [package]
    sed -i '/^\[package\]$/a autobins = false' "$VALIDATOR_TOML"
    cat >> "$VALIDATOR_TOML" << 'EOF'

[[bin]]
name = "soltard-validator"
path = "src/main.rs"

[[bin]]
name = "soltard-test-validator"
path = "src/bin/solana-test-validator.rs"
EOF
    echo "    [ok] Added [[bin]] soltard-validator + soltard-test-validator in ${VALIDATOR_TOML}"
    RENAME_COUNT=$((RENAME_COUNT + 2))
fi

# ledger-tool crate has 1 binary: agave-ledger-tool (main.rs)
LEDGER_TOML="ledger-tool/Cargo.toml"
if [ -f "$LEDGER_TOML" ] && ! grep -q '\[\[bin\]\]' "$LEDGER_TOML"; then
    cat >> "$LEDGER_TOML" << 'EOF'

[[bin]]
name = "soltard-ledger-tool"
path = "src/main.rs"
EOF
    echo "    [ok] Added [[bin]] soltard-ledger-tool in ${LEDGER_TOML}"
    RENAME_COUNT=$((RENAME_COUNT + 1))
fi

# Fix default-run references
for file in $(grep -rl 'default-run' --include="Cargo.toml" 2>/dev/null); do
    if grep -q 'default-run = "agave-validator"' "$file"; then
        sed -i 's/default-run = "agave-validator"/default-run = "soltard-validator"/' "$file"
        echo "    [ok] default-run: agave-validator -> soltard-validator in ${file}"
    fi
    if grep -q 'default-run = "agave-ledger-tool"' "$file"; then
        sed -i 's/default-run = "agave-ledger-tool"/default-run = "soltard-ledger-tool"/' "$file"
        echo "    [ok] default-run: agave-ledger-tool -> soltard-ledger-tool in ${file}"
    fi
done

echo "    Renamed/added ${RENAME_COUNT} binary entries"

# --- Step 3: Patch config directory ---
echo ""
echo "==> [3/5] Patching config directory path..."

CONFIG_RS="cli-config/src/config.rs"
if [ -f "$CONFIG_RS" ]; then
    # Only patch the config dir name, not all "solana" strings
    sed -i 's|\.config/solana|.config/soltard|g' "$CONFIG_RS"
    echo "    [ok] Patched ${CONFIG_RS}"
fi

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
