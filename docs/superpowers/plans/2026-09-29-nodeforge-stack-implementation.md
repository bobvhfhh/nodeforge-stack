# NodeForge Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish an independent NodeForge Stack implementation covering Incus, networking, agent, firewall, and Sing-box operations with safe defaults.

**Architecture:** A small Bash CLI delegates to focused modules. Shared validation, locking, backups, downloads, logging, and confirmation live in `lib/`; modules never execute remote shell and only remove resources they own.

**Tech Stack:** Bash 5+, systemd, nftables with iptables fallback, curl, sha256sum, ShellCheck, and a shell-based mock test harness.

**Spec:** `docs/superpowers/specs/2026-09-29-nodeforge-stack-design.md`

## Global Constraints

- Supported host distributions: Debian 12+, Ubuntu 22.04+, and Alpine 3.19+ for Sing-box only.
- All host-changing commands require root and take an exclusive `flock` lock.
- Plain HTTP endpoints and unverified remote artifacts are rejected by default.
- Network changes must create a backup and provide watchdog rollback.
- Uninstall must be scoped to NodeForge-owned resources.
- Tests must not mutate the host, package database, network, or firewall.

---

### Task 1: Repository foundation and shared safety library

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `NOTICE.md`
- Create: `.gitignore`
- Create: `lib/core.sh`
- Create: `lib/validation.sh`
- Create: `lib/download.sh`
- Create: `tests/test_core.sh`

**Interfaces:**
- `lib/core.sh` exports `nf_log`, `nf_die`, `nf_require_root`, `nf_lock`, `nf_confirm`, `nf_backup_file`, `nf_run`.
- `lib/validation.sh` exports `nf_require_https_url`, `nf_require_ipv4`, `nf_require_ipv6_or_cidr`, and `nf_require_safe_name`.
- `lib/download.sh` exports `nf_download_verified URL DEST SHA256` and refuses non-HTTPS URLs unless `NODEFORGE_INSECURE_DOWNLOAD=1`.

- [ ] Write mock-based tests for URL validation, IPv4 validation, dry-run behavior, and checksum failure.
- [ ] Run `bash tests/test_core.sh`; confirm the tests fail because the libraries do not exist.
- [ ] Implement shared libraries with strict shell options, temporary-file cleanup, atomic writes, and lock handling.
- [ ] Run `bash tests/test_core.sh` and `bash -n lib/*.sh`; confirm all tests pass.
- [ ] Commit `chore: add nodeforge safety foundation`.

### Task 2: CLI dispatcher and configuration

**Files:**
- Create: `bin/nodeforge`
- Create: `lib/config.sh`
- Create: `tests/test_cli.sh`

**Interfaces:**
- `nodeforge --dry-run doctor` prints prerequisites without changing the host.
- Commands dispatch to `modules/{incus,network,firewall,agent,singbox}.sh`.
- `lib/config.sh` exports `nf_config_load`, `nf_config_get`, and `nf_config_set` using an allowlisted `KEY=VALUE` file.

- [ ] Add tests for help output, unknown command errors, config key allowlisting, and dry-run propagation.
- [ ] Implement the dispatcher with predictable exit codes and `--yes`, `--dry-run`, `--verbose`, and `--config` options.
- [ ] Run CLI tests and `bash -n bin/nodeforge lib/config.sh`.
- [ ] Commit `feat: add nodeforge command dispatcher`.

### Task 3: Incus module

**Files:**
- Create: `modules/incus.sh`
- Create: `templates/incus-preseed.yaml`
- Create: `tests/test_incus.sh`

**Interfaces:**
- `nodeforge incus install [--storage dir|btrfs|zfs]` installs dependencies only after prerequisite checks.
- `nodeforge incus init` creates or updates the `nodeforgebr0` network idempotently.
- `nodeforge incus status` reports server, bridge, storage, and container state.
- `nodeforge incus remove` removes only the `nodeforgebr0` network and resources explicitly tagged `nodeforge.owner=incus`.

- [ ] Add command-mocking tests for idempotent network creation and scoped removal.
- [ ] Implement package-manager detection, Incus repository setup, preseed generation, and status output.
- [ ] Run tests with mocked `incus`, `apt-get`, and `systemctl` binaries.
- [ ] Commit `feat: add scoped incus lifecycle module`.

### Task 4: Network transaction module

**Files:**
- Create: `modules/network.sh`
- Create: `tests/test_network.sh`

**Interfaces:**
- `nodeforge network doctor` reports interface, routes, MTU, DNS, forwarding, and firewall compatibility.
- `nodeforge network apply --interface IFACE --ipv4 CIDR --gateway IP [--ipv6 CIDR --ipv6-gateway IP]` validates and stages configuration.
- `nodeforge network rollback BACKUP_ID` restores an earlier backup.

- [ ] Test invalid addresses, generated backup paths, and watchdog command construction without touching real networking.
- [ ] Implement ifupdown and netplan adapters, backup/restore, connectivity probes, and a bounded rollback watchdog.
- [ ] Run mocked network tests and shell syntax checks.
- [ ] Commit `feat: add transactional network management`.

### Task 5: Firewall and abuse protection module

**Files:**
- Create: `modules/firewall.sh`
- Create: `templates/nodeforge.nft`
- Create: `tests/test_firewall.sh`

**Interfaces:**
- `nodeforge firewall apply [--speedtest] [--mining] [--bt] [--mtproto] [--proxy-panels]` renders an explicit rule set.
- `nodeforge firewall status` shows backend, ruleset hash, and enabled protections.
- `nodeforge firewall remove` removes only the `inet nodeforge` table or compatibility chains.

- [ ] Test rule rendering, feature toggles, and cleanup scoping using fake `nft` and `iptables` binaries.
- [ ] Implement nftables-first rules, capability detection, SSH/DNS/ICMP allowlists, connection-state handling, and an iptables fallback.
- [ ] Run firewall tests and ensure unsupported match expressions fail before applying a partial ruleset.
- [ ] Commit `feat: add nftables-first abuse protection`.

### Task 6: Agent and Sing-box modules

**Files:**
- Create: `modules/agent.sh`
- Create: `modules/singbox.sh`
- Create: `templates/incudal-agent.service`
- Create: `templates/sing-box.service`
- Create: `tests/test_agent_singbox.sh`

**Interfaces:**
- `nodeforge agent install --panel URL --token TOKEN --manifest URL` downloads a signed/checksummed artifact and writes a `0600` config.
- `nodeforge agent status|logs|remove` manages only `incudal-agent.service`.
- `nodeforge singbox install --protocol vless-reality|shadowsocks|anytls` writes validated configuration and a service.
- `nodeforge singbox status|remove` manages only NodeForge-owned files.

- [ ] Test rejection of HTTP URLs, malformed manifest entries, checksum mismatch, and generated service hardening.
- [ ] Implement strict manifest parsing, atomic binary install, secret redaction, config validation, and service lifecycle.
- [ ] Run module tests with local fixture artifacts and no network access.
- [ ] Commit `feat: add verified agent and sing-box installers`.

### Task 7: Doctor, uninstall, CI, and documentation

**Files:**
- Modify: `bin/nodeforge`
- Create: `modules/doctor.sh`
- Create: `modules/uninstall.sh`
- Create: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `NOTICE.md`

**Interfaces:**
- `nodeforge doctor` aggregates safe checks and returns nonzero only for actionable failures.
- `nodeforge uninstall --yes` removes only NodeForge-owned files, units, rules, and labeled Incus resources.

- [ ] Add tests for uninstall scope and doctor exit codes.
- [ ] Implement the aggregate doctor report and guarded uninstall with a final resource summary.
- [ ] Add CI for Bash syntax, ShellCheck, and test scripts.
- [ ] Finish README with install, dry-run, rollback, security, support matrix, and development instructions.
- [ ] Run all tests and CI-equivalent commands locally.
- [ ] Commit `docs: complete nodeforge operations guide`.

### Task 8: GitHub publication

**Files:**
- Modify: `.git/config` only through Git commands.

- [ ] Review `git diff --check`, repository contents, secrets, and license/notice files.
- [ ] Check `gh auth status`; stop and request login only if no authenticated account is available.
- [ ] Create `nodeforge-stack` under the authenticated account, push `main`, and set the remote.
- [ ] Verify the repository URL, default branch, and latest commit through GitHub CLI.
- [ ] Commit/push any final README or metadata correction and report the URL.
