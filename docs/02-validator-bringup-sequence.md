# Soltard Dev Cluster Bringup Sequence

## Prerequisites

### System Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install -y \
  build-essential pkg-config libssl-dev libudev-dev \
  clang cmake protobuf-compiler
```

### Rust Toolchain
```bash
# Agave requires specific Rust nightly — check rust-toolchain.toml in repo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# The repo's rust-toolchain.toml will auto-select the correct version
```

### Build from Source
```bash
git clone https://github.com/ItachiDevv/soltard.git
cd soltard
cargo build --release
# Binaries land in target/release/
```

---

## Phase 1: Generate Keypairs

```bash
# Mint authority (controls initial token supply)
solana-keygen new -o config/mint-keypair.json --no-bip39-passphrase

# Bootstrap validator identity
solana-keygen new -o config/validator-keypair.json --no-bip39-passphrase

# Vote account
solana-keygen new -o config/vote-keypair.json --no-bip39-passphrase

# Stake account
solana-keygen new -o config/stake-keypair.json --no-bip39-passphrase

# Faucet keypair
solana-keygen new -o config/faucet-keypair.json --no-bip39-passphrase
```

---

## Phase 2: Create Genesis Block

```bash
solana-genesis \
  --cluster-type development \
  --ledger config/bootstrap-validator-ledger \
  --mint config/mint-keypair.json \
  --bootstrap-validator \
    config/validator-keypair.json \
    config/vote-keypair.json \
    config/stake-keypair.json \
  --bootstrap-validator-lamports 500000000000000000 \
  --bootstrap-validator-stake-lamports 1000000000000 \
  --hashes-per-tick auto \
  --faucet-pubkey config/faucet-keypair.json \
  --faucet-lamports 500000000000000000 \
  --slots-per-epoch 432000 \
  --ticks-per-slot 64 \
  --max-genesis-archive-unpacked-size 1073741824
```

**Key Parameters**:
| Parameter | Purpose | Default |
|-----------|---------|---------|
| `--cluster-type` | development/devnet/testnet/mainnet-beta | development |
| `--hashes-per-tick` | PoH speed (`auto` = as fast as possible) | auto |
| `--lamports` | Total supply in lamports | — |
| `--bootstrap-validator` | Identity, vote, stake keypairs for first validator | required |
| `--faucet-pubkey` | Who can airdrop | — |
| `--faucet-lamports` | How much the faucet holds | — |
| `--slots-per-epoch` | Epoch length | 432000 |

The genesis block hash is derived from these parameters — changing ANY parameter produces a different genesis hash, giving soltard a unique chain identity.

---

## Phase 3: Start Bootstrap Validator

```bash
solana-validator \
  --identity config/validator-keypair.json \
  --vote-account config/vote-keypair.json \
  --ledger config/bootstrap-validator-ledger \
  --rpc-port 8899 \
  --rpc-bind-address 0.0.0.0 \
  --gossip-port 8001 \
  --dynamic-port-range 8002-8020 \
  --no-wait-for-vote-to-start-leader \
  --no-os-network-limits-test \
  --enable-rpc-transaction-history \
  --full-rpc-api \
  --log config/validator.log
```

**Networking Ports**:
| Port | Protocol | Purpose |
|------|----------|---------|
| 8899 | TCP | JSON-RPC HTTP |
| 8900 | TCP | JSON-RPC WebSocket |
| 8001 | UDP | Gossip protocol |
| 8002-8020 | UDP/TCP | Dynamic (TPU, TVU, repair, shreds) |

---

## Phase 4: Start Faucet

```bash
solana-faucet \
  --keypair config/faucet-keypair.json \
  --per-time-cap 1000 \
  --per-request-cap 100
```

Default faucet port: 9900

---

## Phase 5: Configure CLI and Verify

```bash
# Point CLI to local cluster
solana config set \
  --url http://localhost:8899 \
  --keypair config/mint-keypair.json

# Verify cluster is running
solana cluster-version
solana slot
solana block-height
solana epoch-info
curl -s http://localhost:8899 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq

# Test airdrop
solana airdrop 10

# Test transfer
solana transfer <RECIPIENT_ADDRESS> 1
```

---

## Simplified: solana-test-validator

For development, `solana-test-validator` wraps all the above into one command:

```bash
solana-test-validator \
  --reset \
  --rpc-port 8899 \
  --faucet-port 9900 \
  --ledger config/test-ledger \
  --log config/test-validator.log
```

This auto-generates keypairs, creates genesis, starts validator + faucet. The soltard fork will rename this to `soltard-test-validator`.

---

## Health Checks

| Check | Command |
|-------|---------|
| Cluster version | `solana cluster-version` |
| Current slot | `solana slot` |
| Block height | `solana block-height` |
| Epoch info | `solana epoch-info` |
| Validator health | `curl localhost:8899 -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'` |
| Gossip peers | `solana gossip` |
| Validator info | `solana validators` |
