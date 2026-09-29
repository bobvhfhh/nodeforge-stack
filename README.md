# NodeForge Stack

> 本项目基于 [`ceocok/incudal`](https://github.com/ceocok/incudal) 的功能和设计进行复刻与二次开发。

NodeForge Stack is a Linux node-management toolkit for Incus hosts, dual-stack networking, host agents, abuse protection, and Sing-box services. It is a reimplementation and secondary-development project based on the public functionality and design of [`ceocok/incudal`](https://github.com/ceocok/incudal).

It is designed as a safer operational alternative to ad-hoc `curl | bash` installers:

- HTTPS-only downloads with checksum verification
- dry-run support and explicit destructive confirmations
- backups and watchdog rollback for network changes
- scoped cleanup of NodeForge-owned resources
- nftables-first firewall rules with an iptables compatibility path
- modular Bash code that can be tested without changing a real host

## Quick start

```bash
git clone https://github.com/bobvhfhh/nodeforge-stack.git
cd nodeforge-stack
chmod +x bin/nodeforge
sudo ./bin/nodeforge --dry-run doctor
sudo ./bin/nodeforge doctor
```

State-changing commands are deliberately explicit. For example, render a firewall ruleset before applying it:

```bash
./bin/nodeforge firewall render --speedtest --mining --bt --mtproto --proxy-panels
sudo ./bin/nodeforge firewall apply --speedtest --mining --bt
```

Incus and node networking:

```bash
sudo ./bin/nodeforge incus install
sudo ./bin/nodeforge incus init
sudo ./bin/nodeforge network doctor
sudo ./bin/nodeforge network apply --interface eth0 --ipv4 192.0.2.10/24 --gateway 192.0.2.1 --apply
```

The network command validates first. It only edits `/etc/network/interfaces` when `--apply` is supplied, creates a backup under `/var/lib/nodeforge/backups`, and performs a connectivity probe before reporting success. Keep an out-of-band console available.

## Agent: optional

You do not need an Agent to use this project. An Agent is a small background program that reports a server to a separate management panel. If you do not already have such a panel, ignore the Agent feature and run:

```bash
./bin/nodeforge agent explain
```

Only panel operators need the following advanced installation command. The panel provider must supply the URLs, token, and checksums:

```bash
sudo ./bin/nodeforge agent install --panel https://panel.example --token REDACTED \
  --manifest https://panel.example/releases/agent.json --sha256 MANIFEST_SHA256 \
  --binary-url https://panel.example/releases/nodeforge-agent-linux-amd64 \
  --binary-sha256 BINARY_SHA256
sudo ./bin/nodeforge singbox install --protocol vless-reality \
  --binary-url https://github.com/SagerNet/sing-box/releases/download/vX.Y.Z/sing-box \
  --sha256 BINARY_SHA256
```

## Status

The core workflows are implemented. Agent installation is optional and requires an external panel. Sing-box protocol credentials are deployment-specific; the installer creates a restricted configuration directory and only downloads a binary when you provide a verified URL and SHA-256. Run `nodeforge --dry-run doctor` before using a host-changing command.

## Safety

Do not run a remote installer as root without reviewing the exact release. Use a disposable VPS first, keep an out-of-band console, and make a provider snapshot before changing networking or storage.

## License and attribution

NodeForge Stack is released under Apache-2.0. This repository explicitly attributes its upstream reference project: [`ceocok/incudal`](https://github.com/ceocok/incudal). The NodeForge implementation reorganizes and hardens the feature set with a different module structure, safer download rules, scoped cleanup, dry-run support, and CI. See `NOTICE.md` for attribution and licensing details.
