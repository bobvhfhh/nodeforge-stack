#!/usr/bin/env bash

nf_download_verified() {
  local url="$1"
  local destination="$2"
  local expected_sha256="${3:-}"
  local temporary

  if [[ "$url" == file://* ]]; then
    [[ "${NODEFORGE_TEST_MODE:-0}" == "1" ]] || nf_die "file:// downloads are test-only"
    temporary="$(mktemp "${destination}.download.XXXXXX")" || return 1
    cp -- "${url#file://}" "$temporary"
  else
    nf_require_https_url "$url" || return 1
    command -v curl >/dev/null 2>&1 || { nf_die "curl is required"; return 1; }
    temporary="$(mktemp "${destination}.download.XXXXXX")" || return 1
    if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
      --connect-timeout 15 --max-time 300 "$url" -o "$temporary"; then
      rm -f -- "$temporary"
      return 1
    fi
  fi

  if [[ -z "$expected_sha256" && "${NODEFORGE_ALLOW_UNSIGNED:-0}" != "1" ]]; then
    rm -f -- "$temporary"
    nf_die "artifact checksum is required"
    return 1
  fi
  if [[ -n "$expected_sha256" ]]; then
    local actual
    command -v sha256sum >/dev/null 2>&1 || { rm -f -- "$temporary"; nf_die "sha256sum is required"; return 1; }
    actual="$(sha256sum "$temporary" | awk '{print $1}')"
    if [[ "$actual" != "$expected_sha256" ]]; then
      rm -f -- "$temporary"
      nf_die "checksum mismatch for downloaded artifact"
      return 1
    fi
  fi

  if [[ "$NF_DRY_RUN" == "1" ]]; then
    rm -f -- "$temporary"
    nf_info "would install verified artifact at $destination"
    return 0
  fi
  mkdir -p -- "$(dirname -- "$destination")"
  chmod 0755 "$temporary"
  mv -f -- "$temporary" "$destination"
}
