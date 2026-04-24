# ITACHI_REPORT: soltard Phase 2+3 execution

## status: pass

## summary
Built the full soltard fork from source (agave v2.2.6), launched a working dev cluster on cool (Hetzner VPS), confirmed slots advancing, and wired Supabase monitoring with a cron job writing validator status every 60 seconds.

## criteria_results

| Criteria | Status | Details |
|----------|--------|---------|
| Rust toolchain | pass | rustc 1.95.0 installed via rustup |
| clone-and-brand.sh | pass | Branded 7 binaries in agave-fork/ |
| cargo build --release | pass | All 7 binaries built in 41m 13s |
| genesis.sh | pass | Genesis hash: SbB6y2TNzRfep3CnC2SGvAXKh3wkxBLUSDSE793Txi3 |
| dev-cluster.sh | pass | soltard-test-validator running, RPC healthy on :8899 |
| health-check.sh | pass | 66 slots advanced in 30 seconds |
| stop-cluster.sh | pass | Graceful shutdown with PID tracking |
| Supabase SQL applied | pass | Tables exist: cluster_info, validator_status, epoch_history |
| report-status.sh | pass | Writes slot/block/epoch/health to Supabase |
| Cron job | pass | Every 60s, data confirmed flowing |
| Supabase verification | pass | cluster_info: 1 row, validator_status: 68+ rows, epoch_history: 1 row |

## build binary paths and sizes

```
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard           35M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-faucet     16M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-genesis    28M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-keygen    2.7M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-ledger-tool 58M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-test-validator 70M
/home/itachi/soltard-execute-phase-2/agave-fork/target/release/soltard-validator  72M
```

## RPC health response

```json
{"jsonrpc":"2.0","result":"ok","id":1}
```

## slot advance log

```
Initial slot: 0
Final slot: 66
Slots advanced: 66 in 30s
HEALTH CHECK PASSED
```

## cron output (report-status.log)

```
2026-04-24T10:19:02Z | slot=189 block=189 epoch=0 healthy=true version=2.2.6
2026-04-24T10:20:02Z | slot=337 block=337 epoch=0 healthy=true version=2.2.6
2026-04-24T10:21:02Z | slot=485 block=485 epoch=0 healthy=true version=2.2.6
```

## Supabase table counts

```
cluster_info:      1 row
validator_status: 68 rows (growing every 60s)
epoch_history:     1 row
```

## Supabase sample data (validator_status latest 5)

```json
[
  {"id":68,"slot":631,"block_height":631,"is_healthy":true,"recorded_at":"2026-04-24T10:22:01.88869+00:00"},
  {"id":67,"slot":485,"block_height":485,"is_healthy":true,"recorded_at":"2026-04-24T10:21:02.773358+00:00"},
  {"id":66,"slot":337,"block_height":337,"is_healthy":true,"recorded_at":"2026-04-24T10:20:02.354653+00:00"},
  {"id":65,"slot":189,"block_height":189,"is_healthy":true,"recorded_at":"2026-04-24T10:19:01.992137+00:00"},
  {"id":64,"slot":90,"block_height":90,"is_healthy":true,"recorded_at":"2026-04-24T10:18:21.779268+00:00"}
]
```

## learned

- agave cargo build with CARGO_BUILD_JOBS=2 completes in ~41 min on a 4-core/8GB Hetzner VPS
- soltard-test-validator is the easiest way to run a dev cluster (includes faucet, genesis, RPC)
- Port conflicts (faucet :9900) require cleanup of stray processes before restart
- The Supabase REST API works well for cron-based monitoring without needing the CLI
- Background cargo builds in sandboxed shells need explicit PATH (no $HOME/.cargo/env)
