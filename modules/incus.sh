#!/usr/bin/env bash

nf_incus_require() { nf_require_root; nf_require_command incus; }

nf_incus_status() {
  nf_incus_require || return 1
  incus version 2>/dev/null || true
  incus network show nodeforgebr0 2>/dev/null || nf_info "nodeforgebr0 is not configured"
  incus storage list 2>/dev/null || true
}

nf_incus_install() {
  nf_require_root || return 1
  nf_info "Incus installation is distribution-specific; use the signed package source configured by your OS"
  if command -v apt-get >/dev/null 2>&1; then nf_run apt-get update; nf_run apt-get install -y incus; else nf_die "supported package manager not found"; fi
}

nf_incus_init() {
  nf_incus_require || return 1
  nf_lock || return 1
  if incus network show nodeforgebr0 >/dev/null 2>&1; then nf_info "nodeforgebr0 already exists"; return 0; fi
  nf_run incus network create nodeforgebr0 ipv4.address=10.10.0.1/24 ipv4.nat=true ipv6.address=auto ipv6.nat=true "user.nodeforge.owner=incus"
}

nf_incus_remove() {
  nf_incus_require || return 1
  nf_confirm "Remove only NodeForge's Incus bridge?" || return 1
  incus network show nodeforgebr0 >/dev/null 2>&1 && nf_run incus network delete nodeforgebr0 || true
}

nf_incus() {
  case "${1:-status}" in
    install) nf_incus_install ;; init) nf_incus_init ;; status) nf_incus_status ;; remove) nf_incus_remove ;; *) nf_die "usage: nodeforge incus {install|init|status|remove}";;
  esac
}
