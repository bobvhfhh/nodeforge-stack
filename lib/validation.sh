#!/usr/bin/env bash

nf_require_https_url() {
  local value="${1:-}"
  [[ "$value" =~ ^https://[^[:space:]/]+(/[^[:space:]]*)?$ ]] || {
    nf_die "HTTPS URL required: $value"
    return 1
  }
}

nf_require_ipv4() {
  local value="${1:-}"
  local octet
  local -a parts
  IFS='.' read -r -a parts <<<"${value%%/*}"
  [[ "${#parts[@]}" -eq 4 ]] || { nf_die "invalid IPv4 address: $value"; return 1; }
  for octet in "${parts[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] || { nf_die "invalid IPv4 address: $value"; return 1; }
    (( octet <= 255 )) || { nf_die "invalid IPv4 address: $value"; return 1; }
  done
}

nf_require_ipv4_cidr() {
  local value="${1:-}"
  nf_require_ipv4 "$value" || return 1
  if [[ "$value" == */* ]]; then
    local prefix="${value##*/}"
    [[ "$prefix" =~ ^[0-9]+$ && prefix -le 32 ]] || {
      nf_die "invalid IPv4 prefix: $value"
      return 1
    }
  fi
}

nf_require_ipv6_or_cidr() {
  local value="${1:-}"
  local address="$value"
  if [[ "$value" == */* ]]; then
    address="${value%%/*}"
    local prefix="${value##*/}"
    [[ "$prefix" =~ ^[0-9]+$ && prefix -le 128 ]] || {
      nf_die "invalid IPv6 prefix: $value"
      return 1
    }
  fi
  [[ "$address" == *:* && "$address" != *[^0-9a-fA-F:]* ]] || {
    nf_die "invalid IPv6 address: $value"
    return 1
  }
}

nf_require_safe_name() {
  local value="${1:-}"
  [[ "$value" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,62}$ ]] || {
    nf_die "unsafe name: $value"
    return 1
  }
}
