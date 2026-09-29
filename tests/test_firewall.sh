#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/lib/core.sh"
source "$ROOT/modules/firewall.sh"
rules="$(nf_firewall_render --speedtest --bt)"
grep -q 'tcp dport 5201' <<<"$rules"
grep -q '6881-6889' <<<"$rules"
if grep -q '3333' <<<"$rules"; then exit 1; fi
echo 'test_firewall: PASS'
