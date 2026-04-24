# Minimum Branding Diff: agave -> soltard

## Overview

The goal is to create a unique Solana-compatible fork with its own identity while keeping the diff minimal for easier upstream rebasing.

---

## Tier 1: Essential (Unique Chain Identity)

These changes make soltard a distinct chain:

### 1. Genesis Parameters
**File**: `genesis/src/main.rs` and genesis config
- Custom default `--cluster-type` value
- Custom `--hashes-per-tick` if desired
- Custom faucet lamports and supply distribution
- Result: **unique genesis hash** = unique chain

### 2. Cluster/Chain Name
**Files**: Various
- `core/src/cluster_info.rs` — gossip protocol shred version / cluster identification
- `sdk/src/genesis_config.rs` — ClusterType enum (add `Soltard` variant or use `Development`)
- `cli/src/cluster_query.rs` — display names

### 3. Binary Names
**Files**: `Cargo.toml` across workspace
- `solana-validator` -> `soltard-validator`
- `solana-test-validator` -> `soltard-test-validator`
- `solana-genesis` -> `soltard-genesis`
- `solana-faucet` -> `soltard-faucet`
- `solana-keygen` -> `soltard-keygen`
- `solana-cli` -> `soltard` (main CLI)
- `solana-ledger-tool` -> `soltard-ledger-tool`

Approach: Change `[[bin]] name =` in relevant Cargo.toml files. Keep crate names as-is initially to minimize diff.

---

## Tier 2: Branding (User-Facing)

### 4. README and Documentation
- Root `README.md` — soltard branding, description, build instructions
- `LICENSE` — keep Apache 2.0, add copyright line for soltard

### 5. CLI Output Strings
**Files**: `cli/src/*.rs`
- Version strings
- Help text headers
- Default config directory: `~/.config/solana` -> `~/.config/soltard`
- Default keypair path

### 6. RPC Metadata
- `getVersion` response — return soltard version string
- `getClusterNodes` — node identification

---

## Tier 3: Optional (Can Defer)

### 7. Token Naming
- Native token name (SOL -> TARD or custom)
- Displayed in CLI balance outputs, explorer

### 8. Crate Renaming
- Rename `solana-*` crates to `soltard-*`
- MASSIVE diff — defer to later phase
- Only do this if publishing to crates.io

### 9. Program IDs
- Keep standard program IDs for Solana compatibility
- Or change them for a fully independent chain

---

## Recommended Phase 1 Diff (Minimal)

For the initial scaffold, implement only:

1. **Custom genesis script** (`scripts/genesis.sh`) with soltard parameters
2. **Binary renames** via Cargo.toml `[[bin]]` entries (5-10 files)
3. **README.md** with soltard branding
4. **Version string** patch in `cli/src/cli.rs`
5. **Config directory** default change

Estimated diff: ~50-100 lines changed across ~15 files.

This keeps the fork rebasing-friendly while establishing soltard as a distinct chain.

---

## Phase 1 Implementation Plan

Since we're scaffolding (not yet cloning agave), the initial repo will contain:
1. Research documentation (these docs)
2. Scripts that will apply the branding diff to a fresh agave clone
3. Genesis configuration files
4. CI/CD setup for building the fork
5. README with project description and roadmap
