#!/usr/bin/env bash
# stop-cluster.sh — Graceful shutdown of soltard dev cluster
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="${SCRIPT_DIR}/../config/pids"

stop_process() {
    local name="$1"
    local pidfile="${PID_DIR}/${name}.pid"

    if [ ! -f "$pidfile" ]; then
        echo "    No PID file for ${name}"
        return 0
    fi

    local pid
    pid=$(cat "$pidfile")

    if ! kill -0 "$pid" 2>/dev/null; then
        echo "    ${name} (PID ${pid}) already stopped"
        rm -f "$pidfile"
        return 0
    fi

    echo "    Sending SIGTERM to ${name} (PID ${pid})..."
    kill "$pid" 2>/dev/null || true

    for i in $(seq 1 10); do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "    ${name} stopped gracefully"
            rm -f "$pidfile"
            return 0
        fi
        sleep 1
    done

    echo "    ${name} didn't stop, sending SIGKILL..."
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$pidfile"
    echo "    ${name} killed"
}

echo "==> Stopping soltard cluster..."
stop_process "faucet"
stop_process "validator"

for pattern in soltard-validator soltard-faucet soltard-test-validator; do
    STRAY=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$STRAY" ]; then
        echo "    Killing stray ${pattern} processes: ${STRAY}"
        pkill -f "$pattern" 2>/dev/null || true
    fi
done

echo "==> Cluster stopped."
