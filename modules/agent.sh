#!/usr/bin/env bash

NF_AGENT_DIR="${NF_AGENT_DIR:-/etc/nodeforge-agent}"
NF_AGENT_BIN="${NF_AGENT_BIN:-/usr/local/bin/nodeforge-agent}"
nf_agent_install() {
  local panel="" token="" manifest="" checksum="" binary_url="" binary_sha256=""
  while [[ $# -gt 0 ]]; do case "$1" in --panel) panel="$2"; shift 2;; --token) token="$2"; shift 2;; --manifest) manifest="$2"; shift 2;; --sha256) checksum="$2"; shift 2;; --binary-url) binary_url="$2"; shift 2;; --binary-sha256) binary_sha256="$2"; shift 2;; *) nf_die "unknown agent option: $1"; return 1;; esac; done
  nf_require_https_url "$panel" || return 1; nf_require_https_url "$manifest" || return 1; [[ -n "$token" ]] || { nf_die "--token is required"; return 1; }; [[ -n "$checksum" ]] || { nf_die "--sha256 is required"; return 1; }
  [[ -z "$binary_url" ]] || nf_require_https_url "$binary_url" || return 1
  nf_require_root || return 1; nf_lock || return 1; nf_mkdir "$NF_AGENT_DIR"
  nf_download_verified "$manifest" "${NF_AGENT_DIR}/manifest" "$checksum" || return 1
  if [[ -n "$binary_url" ]]; then
    [[ -n "$binary_sha256" ]] || { nf_die "--binary-sha256 is required with --binary-url"; return 1; }
    nf_download_verified "$binary_url" "$NF_AGENT_BIN" "$binary_sha256" || return 1
  fi
  nf_atomic_write "${NF_AGENT_DIR}/config.env" 0600 <<EOF
PANEL_URL=$panel
AGENT_TOKEN=$token
EOF
  if [[ -x "$NF_AGENT_BIN" ]]; then
    nf_atomic_write /etc/systemd/system/nodeforge-agent.service 0644 < "$ROOT/templates/nodeforge-agent.service"
    nf_run systemctl daemon-reload
    nf_run systemctl enable --now nodeforge-agent
  else
    nf_warn "manifest installed but no binary URL was supplied; agent service was not enabled"
  fi
}
nf_agent_status() { systemctl status nodeforge-agent --no-pager 2>/dev/null || nf_info "nodeforge-agent is not installed"; }
nf_agent_remove() { nf_require_root || return 1; nf_confirm "Remove NodeForge agent?" || return 1; nf_run systemctl disable --now nodeforge-agent; nf_run rm -rf -- "$NF_AGENT_DIR" "$NF_AGENT_BIN"; }
nf_agent() { case "${1:-status}" in install) shift; nf_agent_install "$@";; status) nf_agent_status;; remove) nf_agent_remove;; *) nf_die "usage: nodeforge agent {install|status|remove}";; esac; }
