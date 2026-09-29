#!/usr/bin/env bash

NF_SINGBOX_DIR="${NF_SINGBOX_DIR:-/etc/nodeforge-singbox}"
nf_singbox_install() {
  local protocol=""; while [[ $# -gt 0 ]]; do case "$1" in --protocol) protocol="$2"; shift 2;; *) nf_die "unknown Sing-box option: $1"; return 1;; esac; done
  [[ "$protocol" =~ ^(vless-reality|shadowsocks|anytls)$ ]] || { nf_die "unsupported protocol: $protocol"; return 1; }
  nf_require_root || return 1; nf_lock || return 1; nf_mkdir "$NF_SINGBOX_DIR"
  nf_atomic_write "${NF_SINGBOX_DIR}/config.json" 0600 <<EOF
{
  "log": {"level": "info"},
  "inbounds": [],
  "outbounds": [{"type": "direct"}],
  "experimental": {"cache_file": {"enabled": true}}
}
EOF
  nf_info "validated Sing-box $protocol configuration directory; add release-specific inbound credentials before enabling"
}
nf_singbox_status() { systemctl status nodeforge-singbox --no-pager 2>/dev/null || nf_info "nodeforge-singbox is not installed"; }
nf_singbox_remove() { nf_require_root || return 1; nf_confirm "Remove NodeForge Sing-box configuration?" || return 1; nf_run systemctl disable --now nodeforge-singbox; nf_run rm -rf -- "$NF_SINGBOX_DIR"; }
nf_singbox() { case "${1:-status}" in install) shift; nf_singbox_install "$@";; status) nf_singbox_status;; remove) nf_singbox_remove;; *) nf_die "usage: nodeforge singbox {install|status|remove}";; esac; }
