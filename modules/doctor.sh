#!/usr/bin/env bash

nf_doctor() {
  local failures=0 command_name
  nf_info "NodeForge ${NF_VERSION} prerequisite report"
  for command_name in awk curl flock sha256sum; do
    if command -v "$command_name" >/dev/null 2>&1; then nf_info "ok: $command_name"; else nf_warn "missing: $command_name"; failures=$((failures+1)); fi
  done
  if [[ "${EUID:-$(id -u)}" -eq 0 || "${NODEFORGE_TEST_MODE:-0}" == 1 ]]; then nf_info "ok: root privileges"; else nf_warn "not running as root"; failures=$((failures+1)); fi
  command -v systemctl >/dev/null 2>&1 && nf_info "ok: systemd detected" || nf_warn "systemd unavailable (host modules disabled)"
  command -v nft >/dev/null 2>&1 && nf_info "ok: nftables detected" || nf_warn "nftables unavailable (iptables fallback may be used)"
  (( failures == 0 ))
}
