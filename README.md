# soltard

A Solana fork built on [agave](https://github.com/anza-xyz/agave) (the canonical Solana validator client).

## Status

**Phase 1: Research & Scaffold** (complete)

- Fork base: agave (solana-labs/agave) — see [decision doc](docs/01-fork-base-decision.md)
- Validator bringup sequence: [mapped](docs/02-validator-bringup-sequence.md)
- Minimum branding diff: [outlined](docs/03-minimum-branding-diff.md)

## Quick Start

### 1. Clone and brand the fork
```bash
./scripts/clone-and-brand.sh v2.2.6
```

### 2. Build
```bash
cd agave-fork
cargo build --release
```

### 3. Generate genesis and start dev cluster
```bash
./scripts/genesis.sh
./scripts/start-validator.sh
```

### 4. Or use test-validator (simplified)
```bash
soltard-test-validator --reset
```

## Project Structure

```
soltard/
  docs/               # Research and design documents
    01-fork-base-decision.md
    02-validator-bringup-sequence.md
    03-minimum-branding-diff.md
  scripts/            # Automation scripts
    clone-and-brand.sh   # Clone agave + apply soltard branding
    genesis.sh           # Generate genesis block
    start-validator.sh   # Start dev cluster
  config/             # Generated keypairs and ledger (gitignored)
```

## Architecture

soltard is a minimal fork of agave with:
- Renamed binaries (`solana-*` -> `soltard-*`)
- Custom genesis parameters (unique genesis hash)
- Custom config directory (`~/.config/soltard`)
- Version string tagged with `-soltard`

The fork is designed to stay close to upstream agave for easy rebasing.

## License

Apache 2.0 — same as upstream agave.
