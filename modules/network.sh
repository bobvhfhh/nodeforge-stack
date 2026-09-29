#!/usr/bin/env bash

nf_network_doctor() {
  nf_info "default route: $(ip route show default 2>/dev/null || echo unavailable)"
  nf_info "interfaces: $(ip -br link 2>/dev/null || echo unavailable)"
  nf_info "forwarding v4=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo unknown) v6=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo unknown)"
}

nf_network_apply() {
  local iface="" ipv4="" gateway="" ipv6="" ipv6_gateway="" apply=0
  while [[ $# -gt 0 ]]; do case "$1" in --interface) iface="$2"; shift 2;; --ipv4) ipv4="$2"; shift 2;; --gateway) gateway="$2"; shift 2;; --ipv6) ipv6="$2"; shift 2;; --ipv6-gateway) ipv6_gateway="$2"; shift 2;; --apply) apply=1; shift;; *) nf_die "unknown network option: $1"; return 1;; esac; done
  [[ -n "$iface" && -n "$ipv4" && -n "$gateway" ]] || { nf_die "--interface, --ipv4 and --gateway are required"; return 1; }
  nf_require_safe_name "$iface" || return 1; nf_require_ipv4_cidr "$ipv4" || return 1; nf_require_ipv4 "$gateway" || return 1
  [[ -z "$ipv6" ]] || nf_require_ipv6_or_cidr "$ipv6" || return 1
  nf_require_root || return 1; nf_lock || return 1
  nf_info "validated network transaction for $iface ($ipv4 via $gateway${ipv6_gateway:+, IPv6 gateway $ipv6_gateway})"
  (( apply )) || { nf_info "validation only; pass --apply to commit"; return 0; }
  [[ -f /etc/network/interfaces ]] || { nf_die "ifupdown configuration not found; use a distribution adapter before applying"; return 1; }
  local backup; backup="$(nf_backup_file /etc/network/interfaces)"
  nf_atomic_write /etc/network/interfaces 0644 <<EOF
auto lo
iface lo inet loopback

auto $iface
iface $iface inet static
  address $ipv4
  gateway $gateway
  dns-nameservers 1.1.1.1 8.8.8.8
$( [[ -n "$ipv6" ]] && printf '  up ip -6 addr add %s dev %s\n' "$ipv6" "$iface" )
EOF
  nf_run ip route replace default via "$gateway" dev "$iface"
  nf_run ip link set dev "$iface" up
  if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then nf_info "connectivity probe passed; backup: $backup"; else nf_warn "connectivity probe failed; restore with nodeforge network rollback $backup"; return 1; fi
}

nf_network_rollback() { local backup="${1:-}"; [[ -f "$backup" ]] || { nf_die "backup file not found: $backup"; return 1; }; nf_require_root || return 1; nf_run cp -a -- "$backup" /etc/network/interfaces; }
nf_network() { case "${1:-doctor}" in doctor) nf_network_doctor;; apply) shift; nf_network_apply "$@";; rollback) shift; nf_network_rollback "$@";; *) nf_die "usage: nodeforge network {doctor|apply|rollback}";; esac; }
