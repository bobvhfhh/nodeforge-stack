# NodeForge Stack

> 本项目基于 [`ceocok/incudal`](https://github.com/ceocok/incudal) 的公开功能和设计进行复刻与二次开发。
>
> This project is a reimplementation and secondary development based on the public functionality and design of [`ceocok/incudal`](https://github.com/ceocok/incudal).

## 项目简介

NodeForge Stack 是一个面向 Linux VPS/物理机的节点管理工具，覆盖 Incus 容器、双栈网络、主机 Agent、防滥用防火墙和 Sing-box 服务。

它保留了上游项目的主要使用场景，同时进行了独立重构和安全加固：

- HTTPS-only 下载和 SHA-256 校验
- 支持 `--dry-run` 预演和危险操作确认
- 网络配置备份、连通性检测和回滚入口
- 只清理 NodeForge 自己创建的资源
- nftables 优先，并提供兼容路径
- 模块化 Bash 结构、ShellCheck 和 GitHub Actions CI

## Project Overview (English)

NodeForge Stack is a Linux node-management toolkit for VPS and bare-metal hosts. It covers Incus containers, dual-stack networking, an optional host agent, abuse-protection firewall rules, and Sing-box services.

It reimplements the main operational goals of the upstream project while adding safer downloads, dry-run support, backups, scoped cleanup, modular code, and CI checks.

## 快速开始

```bash
git clone https://github.com/bobvhfhh/nodeforge-stack.git
cd nodeforge-stack
chmod +x bin/nodeforge
sudo ./bin/nodeforge --dry-run doctor
sudo ./bin/nodeforge doctor
```

先使用 `--dry-run` 检查环境，再执行会修改主机的命令。

## Quick Start (English)

Run the dry-run doctor before using host-changing commands.

## 常用功能

### 防滥用防火墙

先渲染规则，再应用规则：

```bash
./bin/nodeforge firewall render --speedtest --mining --bt --mtproto --proxy-panels
sudo ./bin/nodeforge firewall apply --speedtest --mining --bt
```

### Incus 和网络

```bash
sudo ./bin/nodeforge incus install
sudo ./bin/nodeforge incus init
sudo ./bin/nodeforge network doctor
sudo ./bin/nodeforge network apply --interface eth0 --ipv4 192.0.2.10/24 --gateway 192.0.2.1 --apply
```

网络命令会先校验参数。只有提供 `--apply` 时才会修改配置，并在 `/var/lib/nodeforge/backups` 保存备份。远程改网络前必须准备云厂商控制台或带外登录方式。

### Incus and Networking (English)

Network changes are validated first, backed up under `/var/lib/nodeforge/backups`, and should only be performed with out-of-band access available.

## Agent 说明

Agent 是服务器上的可选后台程序，用来把主机状态报告给一个独立的管理面板。没有自己的面板时，不需要安装 Agent，Incus、网络、防火墙和 Sing-box 功能都可以正常使用。

查看说明：

```bash
./bin/nodeforge agent explain
```

只有已经拥有管理面板的用户，才需要面板地址、一次性 Token、Agent 下载地址和 SHA-256 校验值。

### Agent (English)

The Agent is an optional background program that reports host status to an external management panel. You do not need it if you do not already have such a panel. Run `./bin/nodeforge agent explain` for details.

## Sing-box

Sing-box 安装需要你提供可信的二进制下载地址和 SHA-256 校验值：

```bash
sudo ./bin/nodeforge singbox install --protocol vless-reality --binary-url https://example.com/sing-box --sha256 YOUR_BINARY_SHA256
```

协议凭据和入站配置属于部署环境信息，项目不会替你猜测或写入真实密钥。

### Sing-box (English)

Sing-box installation requires a trusted binary URL and SHA-256 checksum. Protocol credentials and inbound settings are deployment-specific and are not guessed or embedded by this project.

## 安全提醒

- 不要在不了解内容的情况下直接执行远程 `curl | bash`。
- 生产环境使用前，请先创建云主机快照。
- 修改网络和防火墙前，准备带外控制台。
- Agent Token、面板凭据和二进制校验值不要提交到 Git。
- 卸载前确认目标主机只包含你希望删除的 NodeForge 资源。

## Security Notes (English)

- Do not execute remote `curl | bash` content without reviewing it.
- Create a provider snapshot before production changes.
- Keep out-of-band console access before changing networking or firewall policy.
- Never commit Agent tokens, panel credentials, or private checksums to Git.
- Review the resource summary before uninstalling NodeForge.

## 支持范围

主机管理功能面向 Debian 12+ 和 Ubuntu 22.04+；Sing-box 模块可在支持 systemd 的 Linux 系统上使用。具体包源、内核能力和网络配置仍取决于你的 VPS/IDC 环境。

### Support Matrix (English)

Host-management features target Debian 12+ and Ubuntu 22.04+. The Sing-box module requires a Linux system with systemd. Package sources, kernel capabilities, and network layout remain environment-specific.

## 来源和许可证

本项目明确基于 [`ceocok/incudal`](https://github.com/ceocok/incudal) 的功能和设计进行复刻与二次开发。NodeForge 对代码结构、安全策略、命令入口、测试和文档进行了独立重构。请查看 [`NOTICE.md`](NOTICE.md) 了解来源说明和上游许可证状态。

NodeForge Stack 使用 Apache-2.0 许可证，详见 [`LICENSE`](LICENSE)。

### Attribution and License (English)

This project explicitly attributes [`ceocok/incudal`](https://github.com/ceocok/incudal) as its upstream functional and design reference. NodeForge independently reorganizes the code, security model, command interface, tests, and documentation. See [`NOTICE.md`](NOTICE.md) for attribution and upstream license information.

NodeForge Stack is released under Apache-2.0. See [`LICENSE`](LICENSE).
