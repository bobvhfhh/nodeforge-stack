#!/usr/bin/env bash

NF_ALLOWED_KEYS=(PANEL_URL AGENT_ID AGENT_SECRET AGENT_INTERVAL SINGBOX_VERSION)

nf_config_key_allowed() {
  local key="$1" allowed
  for allowed in "${NF_ALLOWED_KEYS[@]}"; do [[ "$key" == "$allowed" ]] && return 0; done
  return 1
}

nf_config_load() {
  [[ -f "$NF_CONFIG_FILE" ]] || return 0
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"; value="${BASH_REMATCH[2]}"
      nf_config_key_allowed "$key" || { nf_warn "ignoring unknown config key: $key"; continue; }
      printf -v "$key" '%s' "$value"
    fi
  done <"$NF_CONFIG_FILE"
}

nf_config_get() { local key="$1"; nf_config_key_allowed "$key" || return 1; printf '%s\n' "${!key-}"; }

nf_config_set() {
  local key="$1" value="$2" line found=0 tmp
  nf_config_key_allowed "$key" || { nf_die "unknown config key: $key"; return 1; }
  nf_mkdir "$(dirname -- "$NF_CONFIG_FILE")"
  tmp="$(mktemp)" || return 1
  [[ -f "$NF_CONFIG_FILE" ]] && cp -- "$NF_CONFIG_FILE" "$tmp"
  if [[ -s "$tmp" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "$key="* ]]; then printf '%s=%s\n' "$key" "$value"; found=1; else printf '%s\n' "$line"; fi
    done <"$tmp" >"${tmp}.new"
    mv -- "${tmp}.new" "$tmp"
  fi
  [[ "$found" == 1 ]] || printf '%s=%s\n' "$key" "$value" >>"$tmp"
  chmod 0600 "$tmp"; mv -f -- "$tmp" "$NF_CONFIG_FILE"
}
