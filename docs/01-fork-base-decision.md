# Fork Base Decision: agave (solana-labs/agave)

## Date: 2026-04-24
## Status: DECIDED

## Candidates Evaluated

### 1. solana-labs/agave (SELECTED)

**What**: The canonical Solana validator client, maintained by Anza (spun out from Solana Labs in early 2024). Formerly `solana-labs/solana`, renamed to `agave` as part of the multi-client strategy.

**Language**: Rust (Cargo workspace, ~500+ crates)

**License**: Apache 2.0

**Includes**:
- `solana-validator` — full validator node
- `solana-rpc` — JSON-RPC server (built into validator)
- `solana-cli` — command-line tools
- `solana-faucet` — SOL airdrop service
- `solana-test-validator` — single-command dev cluster
- `solana-genesis` — genesis block creation
- `solana-ledger-tool` — ledger inspection/repair
- `solana-bench-tps` — benchmarking

**Key Directories**:
- `validator/` — validator entry point
- `core/` — consensus, banking, replay
- `runtime/` — account state, execution
- `ledger/` — blockstore, shreds
- `gossip/` — cluster discovery protocol
- `rpc/` — JSON-RPC server
- `cli/` — CLI tools
- `genesis/` — genesis creation
- `sdk/` — client SDK
- `programs/` — native programs (system, stake, vote, BPF loader)

**Build**: `cargo build --release` (requires Rust nightly, ~30min on 8-core)

**Maintenance**: Very active, daily commits, release branches (v2.x)

**Advantages**:
- Complete toolchain — everything needed for a chain in one repo
- Largest community, most documentation, most forks
- Clean Cargo workspace — easy to add/remove crates
- Apache 2.0 — full freedom to fork and rebrand
- `solana-test-validator` makes dev iteration fast
- Well-understood genesis and cluster configuration

**Disadvantages**:
- Massive codebase (~750K+ lines of Rust)
- Keeping up with upstream requires effort
- Build times are long

---

### 2. jito-foundation/jito-solana (REJECTED)

**What**: Jito's fork of agave with MEV features (bundle processing, tip distribution, block engine integration).

**Relationship to agave**: Direct fork, periodically rebased on upstream agave releases.

**MEV Features**:
- Transaction bundle processing
- Tip distribution program
- Block engine integration (external service)
- Relayer integration

**Why Rejected**:
- Adds MEV infrastructure complexity we don't need
- Depends on external Jito services (block engine, relayer)
- Rebase lag — always behind upstream agave
- Stripping MEV features is more work than adding features to agave
- If we want MEV later, we can cherry-pick from jito-solana

---

### 3. firedancer-io/firedancer (REJECTED)

**What**: Jump Crypto's independent Solana validator implementation written in C.

**Language**: C (not Rust)

**Current Status**: Frankendancer (hybrid) runs on mainnet; full Firedancer still maturing.

**Why Rejected**:
- Written in C — completely different ecosystem from Solana's Rust tooling
- Missing CLI tools, faucet, test-validator, genesis tooling
- Much smaller community, less documentation
- Harder to maintain for a small team
- Would need to build all dev tooling from scratch or use agave tools anyway
- Performance benefits irrelevant for a dev/custom chain
- License: Apache 2.0 (fine, but ecosystem mismatch is the blocker)

---

## Decision Rationale

**agave is the only viable choice** for a Solana fork project because:

1. **Complete toolchain**: Everything from genesis to faucet to CLI in one repo
2. **Fork-friendly**: Apache 2.0, well-structured Cargo workspace
3. **Community**: Most documentation, most existing forks as references
4. **Dev experience**: `solana-test-validator` enables rapid iteration
5. **Upstream tracking**: Can periodically rebase on agave releases

The tradeoff (large codebase, long builds) is acceptable — we're forking, not rewriting.
