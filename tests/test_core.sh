#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NODEFORGE_TEST_MODE=1
export NF_STATE_DIR="$(mktemp -d)"
export NF_LOCK_FILE="${NF_STATE_DIR}/nodeforge.lock"
trap 'rm -rf -- "$NF_STATE_DIR"' EXIT

# shellcheck source=/dev/null
source "$ROOT/lib/core.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/validation.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/download.sh"

assert_success() { "$@" >/dev/null; }
assert_failure() { if "$@" >/dev/null 2>&1; then return 1; fi; }

assert_success nf_require_https_url https://panel.example.test/api
assert_failure nf_require_https_url http://panel.example.test
assert_success nf_require_ipv4 192.0.2.10
assert_success nf_require_ipv4_cidr 192.0.2.0/24
assert_failure nf_require_ipv4 999.0.2.10
assert_success nf_require_ipv6_or_cidr 2001:db8::1/64
assert_failure nf_require_ipv6_or_cidr not-an-ip
assert_success nf_require_safe_name nodeforge-br0
assert_failure nf_require_safe_name '../escape'

fixture="${NF_STATE_DIR}/fixture"
printf 'nodeforge fixture\n' >"$fixture"
checksum="$(sha256sum "$fixture" | awk '{print $1}')"
export NF_DRY_RUN=0
nf_download_verified "file://$fixture" "${NF_STATE_DIR}/installed" "$checksum"
cmp "$fixture" "${NF_STATE_DIR}/installed"
assert_failure nf_download_verified "file://$fixture" "${NF_STATE_DIR}/bad" "$(printf '%064d' 0)"

export NF_DRY_RUN=1
nf_run touch "${NF_STATE_DIR}/dry-run-must-not-exist"
[[ ! -e "${NF_STATE_DIR}/dry-run-must-not-exist" ]]

printf 'test_core: PASS\n'
