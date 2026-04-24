# Soltard Implementation Plan

## Decision: Fork agave (anza-xyz/agave)
- See [docs/01-fork-base-decision.md](docs/01-fork-base-decision.md) for rationale
- Apache 2.0, complete toolchain, largest community

---

## Phase 1: Minimum Brand-Only Fork (THIS SESSION)

**Goal**: Produce a working `clone-and-brand.sh` that takes a fresh agave checkout and applies the soltard branding diff, creating a buildable soltard fork.

### Deliverables
1. **`scripts/clone-and-brand.sh`** (already exists, needs refinement)
   - Clone agave at a pinned tag (default: v2.2.6)
   - Rename binaries: `solana-*` -> `soltard-*` via Cargo.toml `[[bin]]` entries
   - Patch version string to include `-soltard` suffix
   - Patch default config directory `~/.config/solana` -> `~/.config/soltard`
   - Patch native token display name (SOL -> TARD) where feasible

2. **`scripts/genesis.sh`** (already exists)
   - Custom genesis parameters (unique genesis hash)
   - 500M TARD supply split: 50% bootstrap validator, 50% faucet
   - Development cluster type

3. **`config/genesis-params.env`** (new)
   - Externalized genesis parameters for easy tuning
   - Sourced by genesis.sh

4. **`README.md`** (update)
   - Full soltard branding, build instructions, architecture overview

5. **Verification**: Run `clone-and-brand.sh` dry-run to confirm sed patterns match real agave files

### Files Changed
- `scripts/clone-and-brand.sh` — enhanced branding script
- `scripts/genesis.sh` — use genesis-params.env
- `config/genesis-params.env` — new
- `README.md` — updated branding
- `plan.md` — this file

---

## Phase 2: Dev-Cluster Bringup Script

**Goal**: One-command dev cluster that boots soltard from scratch.

### Deliverables
1. **`scripts/dev-cluster.sh`** — wraps clone-and-brand + build + genesis + validator + faucet
2. **`scripts/health-check.sh`** — polls RPC until healthy, outputs cluster info
3. **`scripts/stop-cluster.sh`** — graceful shutdown + PID cleanup
4. **Systemd unit file** (optional) — `config/soltard-validator.service`
5. **CI workflow** — `.github/workflows/build.yml` for cargo build + test

### Status: STUBBED (scripts created with TODOs)

---

## Phase 3: Supabase Integration

**Goal**: Connect the running soltard cluster to the existing Supabase project (`jfgolkmphrsylthfjrpv`) for metadata, monitoring, and cluster state.

### Deliverables
1. **Supabase schema** — tables for cluster_info, validator_status, epoch_history
2. **`scripts/report-status.sh`** — cron job that polls RPC and writes to Supabase
3. **`scripts/supabase-setup.sql`** — migration file for the schema
4. **Integration with faucet** — optional: log airdrop requests to Supabase

### Status: STUBBED (schema + script outlines only)

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Fork base | agave v2.2.6 | Latest stable, complete toolchain |
| Branding approach | Sed-based script on fresh clone | Minimal diff, easy to rebase on new agave tags |
| Binary names | `soltard-*` | Clear identity, no crate renames needed |
| Config dir | `~/.config/soltard` | Avoids collision with real Solana installs |
| Genesis type | `development` | Dev cluster, fast epochs, auto hashes-per-tick |
| Supabase project | `jfgolkmphrsylthfjrpv` (us-east-1) | Already provisioned |

---

## Open Questions
- Do we want a custom native token name (TARD) or keep SOL?
- Should we support upstream rebase automation (e.g., script to merge new agave tags)?
- CI: GitHub Actions or self-hosted on Hetzner?
