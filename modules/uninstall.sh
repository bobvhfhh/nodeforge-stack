#!/usr/bin/env bash
nf_uninstall() {
  nf_require_root || return 1; nf_confirm "Remove NodeForge-owned services, config, and firewall rules?" || return 1
  command -v nft >/dev/null 2>&1 && nf_run nft delete table inet nodeforge || true
  nf_run systemctl disable --now nodeforge-agent nodeforge-singbox 2>/dev/null || true
  nf_run rm -rf -- /etc/nodeforge /etc/nodeforge-agent /etc/nodeforge-singbox /var/lib/nodeforge
  nf_info "NodeForge-owned files removed; unrelated Incus resources were preserved"
}
