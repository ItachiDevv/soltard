# ITACHI_REPORT: soltard research & bootstrap

## status: pass

## summary
Researched three Solana fork bases (agave, jito-solana, firedancer), selected agave as the fork base, documented the full validator bringup sequence, outlined the minimum branding diff, scaffolded the repo with scripts and docs, created a Supabase project, and pushed to GitHub.

## criteria_results

| Criteria | Status | Details |
|----------|--------|---------|
| Survey fork bases | pass | Evaluated agave, jito-solana, firedancer with detailed comparison |
| Pick fork base with rationale | pass | agave selected — complete toolchain, Apache 2.0, largest community, easiest to fork |
| Map validator bringup sequence | pass | Full sequence documented: keypairs -> genesis -> validator -> faucet -> CLI verify |
| Outline minimum branding diff | pass | 3-tier plan: essential (genesis/binaries), branding (CLI/config), optional (crate renames) |
| Scaffold repo | pass | docs/, scripts/, config/ with clone-and-brand.sh, genesis.sh, start-validator.sh |
| Supabase project | pass | Created "soltard" (id: jfgolkmphrsylthfjrpv) under pumpcaster@proton.me org (us-east-1) |
| GitHub repo | pass | Pushed to ItachiDevv/soltard branch task/research-bootstrap-new |

## deliverables

- **Research docs**: `docs/01-fork-base-decision.md`, `docs/02-validator-bringup-sequence.md`, `docs/03-minimum-branding-diff.md`
- **Scripts**: `scripts/clone-and-brand.sh` (clone agave + apply branding), `scripts/genesis.sh` (generate genesis block), `scripts/start-validator.sh` (start dev cluster)
- **Supabase**: Project `soltard` (jfgolkmphrsylthfjrpv) in pumpcaster@proton.me org
- **GitHub**: https://github.com/ItachiDevv/soltard (branch: task/research-bootstrap-new)

## decision: fork base

**agave** (anza-xyz/agave, formerly solana-labs/solana)

Why not jito-solana: Adds MEV complexity we don't need, always behind upstream, external service dependencies.
Why not firedancer: Written in C (not Rust), missing CLI/faucet/test-validator tooling, much smaller community.

## next steps (phase 2)

1. Run `clone-and-brand.sh` to actually clone agave and apply branding
2. Build the fork (`cargo build --release` — needs beefy machine, ~30min)
3. Run genesis.sh and start-validator.sh to verify the dev cluster boots
4. Merge task/research-bootstrap-new to main
5. Set up CI/CD for automated builds
6. Design Supabase schema for cluster metadata/monitoring

## learned

- agave is the clear choice for any Solana fork — it's the only option that includes the complete toolchain (validator + RPC + CLI + faucet + test-validator + genesis) in one repo
- Firedancer is impressive for performance but impractical as a fork base due to missing dev tooling and C language mismatch with the Solana ecosystem
- The minimum viable branding diff for a Solana fork is ~50-100 lines: binary renames in Cargo.toml, custom genesis params, config directory path, version string
- Genesis hash uniqueness comes automatically from parameter changes — no need to modify hashing code
- Supabase Management API requires organization_id, not just the access token — must list orgs first
