# NodeForge Stack

NodeForge Stack is an independent Linux node-management toolkit for Incus hosts, dual-stack networking, host agents, abuse protection, and Sing-box services.

It is designed as a safer operational alternative to ad-hoc `curl | bash` installers:

- HTTPS-only downloads with checksum verification
- dry-run support and explicit destructive confirmations
- backups and watchdog rollback for network changes
- scoped cleanup of NodeForge-owned resources
- nftables-first firewall rules with an iptables compatibility path
- modular Bash code that can be tested without changing a real host

## Quick start

```bash
git clone https://github.com/YOUR_ACCOUNT/nodeforge-stack.git
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

## Status

The repository is under active development. Incus and firewall workflows are available now; distribution-specific package and artifact adapters are intentionally guarded and should be completed against your release infrastructure before production use. Run `nodeforge --dry-run doctor` before using a host-changing command.

## Safety

Do not run a remote installer as root without reviewing the exact release. Use a disposable VPS first, keep an out-of-band console, and make a provider snapshot before changing networking or storage.

## License and attribution

NodeForge Stack is released under Apache-2.0. Its functional requirements were informed by the public `ceocok/incudal` project; this repository is an independent implementation and does not redistribute that project's source code. See `NOTICE.md`.
