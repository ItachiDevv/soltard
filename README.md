# soltard

A Solana-compatible blockchain fork built on [agave](https://github.com/anza-xyz/agave) (the canonical Solana validator client by Anza).

## What is soltard?

soltard is a branded Solana fork with its own chain identity (unique genesis hash), renamed binaries, and custom configuration. It stays close to upstream agave for easy rebasing while establishing a distinct network.

### Key Differences from Solana

| Feature | Solana | soltard |
|---------|--------|---------|
| Binary prefix | `solana-*` / `agave-*` | `soltard-*` |
| Config dir | `~/.config/solana/` | `~/.config/soltard/` |
| Genesis hash | Solana mainnet/devnet | Unique (custom params) |
| Cluster type | mainnet-beta | development |
| Fork base | — | agave v2.2.6 |

## Quick Start

### 1. Clone and brand the fork

```bash
./scripts/clone-and-brand.sh v2.2.6
```

This clones agave at the specified tag and applies soltard branding (binary renames, config path, version string).

### 2. Build

```bash
cd agave-fork
cargo build --release
```

Requires Rust nightly (auto-selected via `rust-toolchain.toml` in the fork).

### 3. Generate genesis and start dev cluster

```bash
# Customize genesis params (optional)
vim config/genesis-params.env

# Generate keypairs + genesis block
./scripts/genesis.sh

# Start bootstrap validator + faucet
./scripts/start-validator.sh
```

### 4. Or use test-validator (simplified)

```bash
soltard-test-validator --reset
```

## Project Structure

```
soltard/
  plan.md                          # Implementation plan (3 phases)
  docs/                            # Research and design documents
    01-fork-base-decision.md       # Why agave (not jito/firedancer)
    02-validator-bringup-sequence.md # 11-step cluster bringup
    03-minimum-branding-diff.md    # Branding diff specification
  scripts/
    clone-and-brand.sh             # Clone agave + apply soltard branding
    genesis.sh                     # Generate genesis block
    start-validator.sh             # Start dev cluster
  config/
    genesis-params.env             # Tunable genesis parameters
```

## Binaries

After building, `target/release/` contains:

| Binary | Purpose |
|--------|---------|
| `soltard-validator` | Full validator node |
| `soltard-genesis` | Genesis block creation |
| `soltard-test-validator` | One-command dev cluster |
| `soltard-faucet` | Airdrop service |
| `soltard-keygen` | Keypair generation |
| `soltard-ledger-tool` | Ledger inspection/repair |
| `soltard` | CLI (replaces `solana` command) |

## Genesis Parameters

Configured via `config/genesis-params.env`:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `SOLTARD_CLUSTER_TYPE` | `development` | Cluster mode |
| `SOLTARD_VALIDATOR_LAMPORTS` | 500M TARD | Bootstrap validator allocation |
| `SOLTARD_FAUCET_LAMPORTS` | 500M TARD | Faucet allocation |
| `SOLTARD_SLOTS_PER_EPOCH` | 432,000 | Epoch length |
| `SOLTARD_HASHES_PER_TICK` | `auto` | PoH speed |

## Architecture

soltard applies a minimal branding diff to agave via `clone-and-brand.sh`:
1. Binary renames in `Cargo.toml` `[[bin]]` entries (~7 files)
2. Config directory path in `cli-config/src/config.rs`
3. Version string suffix
4. Custom genesis parameters (produces unique genesis hash)

This approach keeps the fork rebasing-friendly — when a new agave release drops, re-run `clone-and-brand.sh` on the new tag.

## Supabase

Cluster metadata is tracked in Supabase project `jfgolkmphrsylthfjrpv` (us-east-1). Schema and integration scripts are planned for Phase 3.

## License

Apache 2.0 — same as upstream agave.
