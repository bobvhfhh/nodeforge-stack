#!/usr/bin/env bash

# Shared runtime for NodeForge modules. This file is sourced by bin/nodeforge.

NF_VERSION="${NF_VERSION:-0.1.0}"
NF_STATE_DIR="${NF_STATE_DIR:-/var/lib/nodeforge}"
NF_LOCK_FILE="${NF_LOCK_FILE:-/run/lock/nodeforge.lock}"
NF_CONFIG_FILE="${NF_CONFIG_FILE:-/etc/nodeforge/config.env}"
NF_DRY_RUN="${NF_DRY_RUN:-0}"
NF_YES="${NF_YES:-0}"
NF_VERBOSE="${NF_VERBOSE:-0}"
NF_LOCK_FD="${NF_LOCK_FD:-}"

nf_log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

nf_info() { nf_log INFO "$@"; }
nf_warn() { nf_log WARN "$@" >&2; }
nf_error() { nf_log ERROR "$@" >&2; }

nf_die() {
  nf_error "$*"
  return 1
}

nf_require_root() {
  if [[ "${NODEFORGE_TEST_MODE:-0}" == "1" ]]; then
    return 0
  fi
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || nf_die "root privileges are required"
}

nf_require_command() {
  command -v "$1" >/dev/null 2>&1 || nf_die "required command not found: $1"
}

nf_run() {
  if [[ "$NF_DRY_RUN" == "1" ]]; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  if [[ "$NF_VERBOSE" == "1" ]]; then
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
  fi
  "$@"
}

nf_mkdir() {
  nf_run mkdir -p -- "$1"
}

nf_atomic_write() {
  local target="$1"
  local mode="${2:-0600}"
  local parent tmp
  parent="$(dirname -- "$target")"
  nf_mkdir "$parent"
  if [[ "$NF_DRY_RUN" == "1" ]]; then
    nf_info "would write $target (mode $mode)"
    cat >/dev/null
    return 0
  fi
  tmp="$(mktemp "${target}.tmp.XXXXXX")" || return 1
  trap 'rm -f -- "$tmp"' RETURN
  cat >"$tmp"
  chmod "$mode" "$tmp"
  mv -f -- "$tmp" "$target"
  trap - RETURN
}

nf_backup_file() {
  local source="$1"
  local stamp backup_dir backup
  [[ -e "$source" ]] || return 0
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_dir="${NF_STATE_DIR}/backups"
  nf_mkdir "$backup_dir"
  backup="${backup_dir}/$(basename -- "$source").${stamp}"
  nf_run cp -a -- "$source" "$backup"
  printf '%s\n' "$backup"
}

nf_lock() {
  [[ -n "$NF_LOCK_FD" ]] && return 0
  [[ "$NF_DRY_RUN" == "1" ]] && return 0
  nf_mkdir "$(dirname -- "$NF_LOCK_FILE")"
  if ! command -v flock >/dev/null 2>&1; then
    nf_die "flock is required for state-changing commands"
    return 1
  fi
  eval "exec {NF_LOCK_FD}>\"$NF_LOCK_FILE\""
  flock -n "$NF_LOCK_FD" || nf_die "another NodeForge operation is already running"
}

nf_unlock() {
  if [[ -n "$NF_LOCK_FD" ]]; then
    flock -u "$NF_LOCK_FD" 2>/dev/null || true
    eval "exec ${NF_LOCK_FD}>&-" || true
    NF_LOCK_FD=""
  fi
}

nf_confirm() {
  local prompt="${1:-Continue?}"
  [[ "$NF_YES" == "1" ]] && return 0
  [[ -t 0 ]] || nf_die "non-interactive execution requires --yes: $prompt"
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

nf_cleanup_runtime() {
  nf_unlock
}

trap nf_cleanup_runtime EXIT
