-- supabase-setup.sql — Soltard cluster monitoring schema
-- Target: Supabase project jfgolkmphrsylthfjrpv (us-east-1)
--
-- Applied to Supabase project jfgolkmphrsylthfjrpv via REST API
-- Tables: cluster_info, validator_status, epoch_history

-- Cluster info: tracks the running soltard cluster
CREATE TABLE IF NOT EXISTS cluster_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cluster_name TEXT NOT NULL DEFAULT 'soltard-dev',
    genesis_hash TEXT,
    rpc_url TEXT NOT NULL DEFAULT 'http://localhost:8899',
    ws_url TEXT DEFAULT 'ws://localhost:8900',
    cluster_type TEXT DEFAULT 'development',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Validator status: periodic snapshots from health checks
CREATE TABLE IF NOT EXISTS validator_status (
    id BIGSERIAL PRIMARY KEY,
    cluster_id UUID REFERENCES cluster_info(id),
    slot BIGINT,
    block_height BIGINT,
    epoch BIGINT,
    epoch_slot BIGINT,
    version TEXT,
    is_healthy BOOLEAN DEFAULT true,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Epoch history: one row per epoch transition
CREATE TABLE IF NOT EXISTS epoch_history (
    id BIGSERIAL PRIMARY KEY,
    cluster_id UUID REFERENCES cluster_info(id),
    epoch BIGINT NOT NULL,
    start_slot BIGINT,
    end_slot BIGINT,
    slot_count BIGINT,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_validator_status_cluster ON validator_status(cluster_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_epoch_history_cluster ON epoch_history(cluster_id, epoch DESC);
