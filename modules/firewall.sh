#!/usr/bin/env bash

nf_firewall_render() {
  local speed=0 mining=0 bt=0 mtproto=0 panels=0 arg
  for arg in "$@"; do case "$arg" in --speedtest) speed=1;; --mining) mining=1;; --bt) bt=1;; --mtproto) mtproto=1;; --proxy-panels) panels=1;; esac; done
  cat <<EOF
table inet nodeforge {
  chain forward { type filter hook forward priority -50; policy accept;
    ct state invalid drop
    iifname "nodeforgebr0" udp dport 53 accept
$( (( speed )) && printf '    tcp dport 5201 reject with tcp reset\n' )
$( (( mining )) && printf '    tcp dport {3333,4444,5555,6666,7777,8888,9999} reject with tcp reset\n' )
$( (( bt )) && printf '    tcp dport {6881-6889,6969,51413} drop\n    udp dport {6881-6889,6969,51413} drop\n' )
$( (( mtproto )) && printf '    tcp payload content "eeeeeeee" reject with tcp reset\n' )
$( (( panels )) && printf '    tcp dport {2053,2083,2087,2096} drop\n' )
  }
}
EOF
}

nf_firewall_apply() { nf_require_root || return 1; nf_lock || return 1; local rules; rules="$(nf_firewall_render "$@")"; [[ -n "$rules" ]] || return 1; if command -v nft >/dev/null 2>&1; then printf '%s\n' "$rules" | nf_run nft -f -; else nf_warn "nft unavailable; no fallback rules applied"; return 1; fi; }
nf_firewall_status() { if command -v nft >/dev/null 2>&1; then nft list table inet nodeforge 2>/dev/null || nf_info "NodeForge firewall table is not installed"; else nf_info "nft is unavailable"; fi; }
nf_firewall_remove() { nf_require_root || return 1; nf_confirm "Remove NodeForge firewall rules?" || return 1; if command -v nft >/dev/null 2>&1; then nf_run nft delete table inet nodeforge || true; fi; }
nf_firewall() { case "${1:-status}" in apply) shift; nf_firewall_apply "$@";; status) nf_firewall_status;; remove) nf_firewall_remove;; render) shift; nf_firewall_render "$@";; *) nf_die "usage: nodeforge firewall {apply|status|remove|render}";; esac; }
