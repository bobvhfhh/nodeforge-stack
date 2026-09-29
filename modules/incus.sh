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
  if command -v incus >/dev/null 2>&1; then nf_info "Incus is already installed"; return 0; fi
  if command -v apt-get >/dev/null 2>&1; then
    nf_run apt-get update
    nf_run apt-get install -y ca-certificates curl gpg
    if [[ "${NF_DRY_RUN:-0}" != 1 ]]; then
      local codename
      # shellcheck disable=SC1091
      codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
      [[ -n "$codename" ]] || { nf_die "could not determine Debian/Ubuntu codename"; return 1; }
      nf_mkdir /etc/apt/keyrings
      curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 https://pkgs.zabbly.com/key.asc | gpg --dearmor --yes -o /etc/apt/keyrings/zabbly.gpg
      nf_atomic_write /etc/apt/sources.list.d/zabbly-incus-stable.sources 0644 <<EOF
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $codename
Components: main
Signed-By: /etc/apt/keyrings/zabbly.gpg
EOF
    fi
    nf_run apt-get update
    nf_run apt-get install -y incus
  else
    nf_die "supported package manager not found (Debian/Ubuntu apt-get required)"
  fi
}

nf_incus_init() {
  nf_incus_require || return 1
  nf_lock || return 1
  if incus network show nodeforgebr0 >/dev/null 2>&1; then nf_info "nodeforgebr0 already exists"; return 0; fi
  nf_run incus network create nodeforgebr0 ipv4.address=10.10.0.1/24 ipv4.nat=true ipv6.address=auto ipv6.nat=true "user.nodeforge.owner=incus"
  nf_run incus profile device add default eth0 nic network=nodeforgebr0 2>/dev/null || true
}

nf_incus_remove() {
  nf_incus_require || return 1
  nf_confirm "Remove only NodeForge's Incus bridge?" || return 1
  if incus network show nodeforgebr0 >/dev/null 2>&1; then nf_run incus network delete nodeforgebr0; fi
}

nf_incus() {
  case "${1:-status}" in
    install) nf_incus_install ;; init) nf_incus_init ;; status) nf_incus_status ;; remove) nf_incus_remove ;; *) nf_die "usage: nodeforge incus {install|init|status|remove}";;
  esac
}
