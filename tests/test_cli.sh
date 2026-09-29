#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NODEFORGE_TEST_MODE=1
NF_STATE_DIR="$(mktemp -d)"
export NF_STATE_DIR
NF_LOCK_FILE="$NF_STATE_DIR/lock"
export NF_LOCK_FILE
trap 'rm -rf -- "$NF_STATE_DIR"' EXIT
help="$("$ROOT"/bin/nodeforge --help)"
grep -q 'NodeForge Stack' <<<"$help"
[[ "$("$ROOT"/bin/nodeforge version)" == "0.1.0" ]]
if "$ROOT/bin/nodeforge" unknown >/dev/null 2>&1; then exit 1; fi
echo 'test_cli: PASS'
