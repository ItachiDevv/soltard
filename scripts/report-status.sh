#!/usr/bin/env bash
# report-status.sh — Poll soltard RPC and write status to Supabase
# Designed to run as a cron job
#
# Usage: ./scripts/report-status.sh
#
# Requires: SUPABASE_URL and SUPABASE_KEY environment variables
# (source ~/.itachi-api-keys for these)
#
# STATUS: STUB — Phase 3 implementation pending
set -euo pipefail

# source ~/.itachi-api-keys 2>/dev/null || true

RPC_URL="${SOLTARD_RPC_URL:-http://localhost:8899}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_KEY="${SUPABASE_KEY:-}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo "ERROR: SUPABASE_URL and SUPABASE_KEY must be set"
    exit 1
fi

# TODO: Implement status reporting
# 1. Query RPC for health, slot, block-height, epoch-info, version
# 2. POST to Supabase validator_status table
# 3. Check for epoch transitions and update epoch_history

echo "[STUB] Status reporting not yet implemented."
echo "Will poll ${RPC_URL} and write to Supabase project jfgolkmphrsylthfjrpv"
