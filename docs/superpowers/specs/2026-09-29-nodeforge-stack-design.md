# NodeForge Stack Design

## Goal

Create an independent, maintainable Linux node-management toolkit that covers the operational capabilities users need from Incudal while improving supply-chain security, rollback behavior, idempotency, and documentation.

## Scope

The first release covers five cooperating areas:

1. Incus host installation and lifecycle management.
2. IPv4/IPv6 NAT, routed networking, DNS/MTU repair, and transactional network changes.
3. Host-agent installation and service management.
4. RFW-style abuse protection with nftables-first rules and an iptables compatibility path.
5. Sing-box installation/configuration and service management.

The project is an independent implementation. It may describe compatibility with Incudal, but it does not copy source files or claim the original project's license.

## Architecture

`bin/nodeforge` is the only user-facing entry point. It loads small shell libraries from `lib/`, then dispatches to modules under `modules/`. Modules expose `check`, `apply`, `status`, and `remove` operations where applicable. Configuration is stored in `/etc/nodeforge/config.env` with mode `0600`; generated systemd units and firewall rules are marked with `nodeforge` comments so cleanup can target only resources created by this project.

All downloads use HTTPS, temporary files, content validation, and atomic replacement. Remote agent configuration is parsed as a strict `KEY=VALUE` document with an allowlist; arbitrary remote shell is never executed. Destructive operations require an explicit confirmation unless `--yes` is supplied, and network changes create a timestamped backup plus a watchdog rollback transaction.

## Security decisions

- Reject plain HTTP URLs for panel, binary, and manifest endpoints.
- Require SHA-256 metadata for agent and Sing-box artifacts; allow an explicit `--insecure-download` only for local development.
- Never pipe network responses to a shell.
- Never use `source` on network-provided content.
- Use `flock` for concurrent state-changing commands.
- Limit uninstall to resources labeled or named by NodeForge; never purge all Incus resources by default.
- Prefer nftables; detect and report unsupported matches before changing policy.

## Compatibility

Supported target platforms are Debian 12+, Ubuntu 22.04+, and Alpine 3.19+ for the Sing-box module. The host-management modules require systemd and root. Commands fail early with a clear prerequisite error when a platform is unsupported.

## Testing and release

The repository includes shell syntax checks, ShellCheck in CI, a command-mocking test harness for validation and dry-run behavior, and documentation examples that use `--dry-run`. No test invokes package managers, changes host networking, or mutates firewall state.

## Documentation and attribution

README is bilingual at the command-reference level and documents risks, backups, rollback, supported distributions, and example workflows. `NOTICE.md` credits `ceocok/incudal` as a functional reference without redistributing its source. The new implementation is released under Apache-2.0.
