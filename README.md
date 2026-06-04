# Homelab

Self-hosted infrastructure project built to run production-like services at home using Docker Compose, Linux networking, reverse proxying, local DNS, VPN-only remote access, persistent storage, and selective redundancy.

This repo is the configuration source for a single-node Ubuntu Server homelab that supports my household while giving me hands-on practice with DevOps fundamentals: container orchestration, service discovery, TLS, DNS, storage layout, secret handling, troubleshooting, and infrastructure documentation.

## Project Goals

- Replace cloud subscriptions with self-hosted services while keeping family access simple and reliable.
- Centralize infrastructure configuration in Git so services can be reviewed, rebuilt, and documented consistently.
- Practice DevOps skills in a real environment with persistent data, user traffic, networking constraints, and operational tradeoffs.
- Keep remote access private by using a mesh VPN instead of exposing home network ports directly to the internet.

## Infrastructure Overview

| Area | Implementation |
|---|---|
| Host | Single physical Ubuntu Server machine |
| Hardware | 32 GB RAM, 500 GB NVMe cache/system storage, 30 TB+ multi-HDD storage pool, reused older PC hardware |
| Runtime | Docker Compose, organized as a monorepo with one compose stack per service area |
| Reverse proxy | Traefik with Docker provider labels and HTTPS routes for friendly service domains |
| DNS | Pi-hole for local DNS records and network-wide ad blocking |
| Remote access | Headscale-managed Tailscale mesh VPN from approved devices only |
| Storage | mergerfs storage pool with SnapRAID selective redundancy for important data |
| Users | Household usage for approximately 6 family members |
| Scale | 20+ containers across productivity, media, DNS, smart home, and AI services |

## Architecture

```text
Approved devices
    |
    | Tailscale client
    v
Headscale control server on VPS
    |
    | Private mesh VPN
    v
Home Ubuntu Server
    |
    | Docker external network: homelab
    v
Traefik reverse proxy + Pi-hole local DNS
    |
    | HTTPS routes such as service.example.com
    v
Docker Compose service stacks
```

Most services are reachable through Traefik using DNS names instead of direct IP addresses. Pi-hole provides local DNS records and ad blocking at the network level. Remote access is intentionally restricted to devices enrolled through Headscale/Tailscale, so the home network does not require broadly exposed inbound service ports.

## Repository Structure

Each major service has its own directory and `docker-compose.yml` file. This keeps service configuration isolated while still allowing the whole homelab to be managed from one Git repository.

| Path | Purpose |
|---|---|
| `traefik/` | Reverse proxy, HTTPS routing, ACME certificate configuration, Docker label discovery |
| `pihole/` | Local DNS and network-wide ad blocking |
| `nextcloud/` | File sync and personal cloud with MariaDB and Redis |
| `immich/` | Photo/video backup with PostgreSQL, Valkey/Redis-compatible cache, and ML service |
| `media/` | Media automation stack with VPN-isolated download services |
| `jellyfin/` | Self-hosted media streaming |
| `home-assistant/` | Smart home automation |
| `actual/` | Personal finance service |
| `calibre-web-automated/` | Ebook library automation |
| `stirling-pdf/` | Self-hosted PDF tools |
| `ollama/` | Local AI model runtime |
| `voice-assistant/` | Local voice assistant components |
| `matter/` | Matter and Thread smart home support |
| `sparkyfitness/` | Self-hosted fitness tracking |

## DevOps Skills Demonstrated

- Containerized service deployment with Docker Compose, restart policies, environment files, persistent volumes, and service dependencies.
- Reverse proxy configuration with Traefik, Docker labels, HTTPS entrypoints, ACME DNS challenge certificates, and per-service routing rules.
- Network design using a shared external Docker network for proxied services and internal-only Docker networks for databases and caches.
- DNS administration with Pi-hole for local service discovery and network-wide ad blocking.
- Private remote access using Headscale/Tailscale instead of exposing the homelab directly to the public internet.
- Stateful workload management for applications such as Nextcloud and Immich, including databases, caches, and storage paths.
- Storage planning with HDD-backed persistent data, NVMe-backed cache/system storage, mergerfs pooling, and SnapRAID selective redundancy.
- Secret hygiene through ignored `.env` files, example environment variables, and password/API key storage outside the repository.
- Operational troubleshooting across Linux permissions, Docker networking, DNS resolution, reverse proxy routing, and container health.

## Networking And Access

Traefik is the primary ingress layer. Services opt in to routing with labels such as `traefik.enable=true`, host rules, TLS entrypoints, and internal service ports. Pi-hole maps friendly local domains to the homelab, so services can be accessed by name instead of IP address.

Remote access is handled through a private Tailscale-style mesh VPN controlled by a self-hosted Headscale instance on a VPS. Only approved devices can join the tailnet and reach the homelab remotely.

## Storage And Data

Persistent application data is stored outside containers and mapped into services with Docker volumes or bind mounts. Large user data, such as Nextcloud files and Immich media, lives on the HDD-backed storage pool. Cache and system workloads use the NVMe where appropriate.

SnapRAID and mergerfs are used as a cost-conscious storage strategy. Important personal data, including Nextcloud and Immich data, receives selective redundancy, while replaceable media is not duplicated to conserve storage.

## Security Decisions

- VPN-only remote access for private services.
- No intentional public exposure of application dashboards from the home network.
- Traefik-managed HTTPS for clean and encrypted service access.
- Internal Docker networks for database and cache containers that should not be directly reachable from the shared proxy network.
- Secrets and credentials excluded from Git with `.gitignore` and managed separately in Bitwarden.
- LinuxServer.io images are used where practical for consistent UID/GID-based file permissions.

## Current Limitations And Next Steps

This homelab is intentionally practical rather than over-engineered. The current deployment process is manual Docker Compose, but the repo is structured so future automation can be added incrementally.

Planned improvements:

- Add automated container update management, likely with Watchtower or Renovate.
- Add infrastructure automation with Ansible for repeatable host setup.
- Add monitoring and alerting with tools such as Prometheus, Grafana, Uptime Kuma, or Beszel.
- Add documented backup and restore runbooks for databases and application data.
- Add CI checks for compose syntax and secret scanning.

## Images

### Anti-Bot

- [Byparr](https://github.com/ThePhaseless/Byparr)

### Books

- [Calibre-Web-Automated](https://github.com/crocodilestick/Calibre-Web-Automated)

### Budget

- [Actual Budget](https://actualbudget.org/docs/install/docker/)

### Cloud

- [Nextcloud](https://docs.linuxserver.io/images/docker-nextcloud/)
    - [MariaDB](https://docs.linuxserver.io/images/docker-mariadb/)

### DNS

- [Pi-hole](https://github.com/pi-hole/docker-pi-hole)

### Downloaders

- [qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent/)

### Fitness

- [SparkyFitness](https://codewithcj.github.io/SparkyFitness/install/docker-compose)

### Home Automation

- [Home Assistant](https://docs.linuxserver.io/images/docker-homeassistant/)
    - [Matter Server](https://github.com/matter-js/python-matter-server/blob/main/docs/docker.md)
    - [Ollama](https://hub.docker.com/r/ollama/ollama)
    - [Open Thread Border Router](https://github.com/ownbee/hass-otbr-docker)
    - [Piper](https://hub.docker.com/r/rhasspy/wyoming-piper)
    - [Whisper](https://docs.linuxserver.io/images/docker-faster-whisper/)

### Indexers

- [Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/)

### Media Management

- [Immich](https://docs.immich.app/install/docker-compose/)
- [Jellyseerr](https://docs.jellyseerr.dev/getting-started/docker)
- [qBit_Manage](https://github.com/StuffAnThings/qbit_manage/wiki/Docker-Installation)
- [Radarr](https://docs.linuxserver.io/images/docker-radarr/)
- [Sonarr](https://docs.linuxserver.io/images/docker-sonarr/)

### Media Servers

- [Jellyfin](https://docs.linuxserver.io/images/docker-jellyfin/)

### PDF

- [Stirling-PDF](https://docs.stirlingpdf.com/Installation/Docker%20Install)

### VPN

- [Gluetun (ProtonVPN)](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md)
