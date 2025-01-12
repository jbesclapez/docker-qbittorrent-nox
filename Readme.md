.. ::img/GhostTracker_logo.png

.. ::img/GhostTracker.png

# GhostTracker for qBittorrent-nox Docker Image [![GitHub Actions CI Status](https://github.com/qbittorrent/docker-qbittorrent-nox/actions/workflows/release.yaml/badge.svg)](https://github.com/qbittorrent/docker-qbittorrent-nox/actions)

GhostTracker is a custom version of libtorrent integrated into a Docker image for qBittorrent-nox. This version modifies tracker reporting behavior to provide enhanced privacy features. It compiles qBittorrent version `5.0.3` with the GhostTracker libtorrent fork. 

Repository on Docker Hub: https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox \
Repository on GitHub: https://github.com/jbesclapez/docker-qbittorrent-nox

## Supported architectures

* linux/386
* linux/amd64
* linux/arm/v6
* linux/arm/v7
* linux/arm64/v8
* linux/riscv64

## Features
- Built with the custom GhostTracker libtorrent fork.
- Privacy-focused changes in libtorrent to modify tracker reporting behavior.
- Fully functional qBittorrent WebUI.

## Reporting bugs

If the problem is related to Docker, please report it to this repository: \
https://github.com/jbesclapez/docker-qbittorrent-nox/issues

If the problem is with qBittorrent itself, please report the issue to its main repository: \
https://github.com/qbittorrent/qBittorrent/issues

## Usage

### 1. Prerequisites

- **Docker**: Install Docker from https://docs.docker.com/get-docker/
- **Docker Compose**: Recommended for easier setup, install from https://docs.docker.com/compose/install/

---

### 2. Download this repository

Clone or download this repository:
```bash
git clone https://github.com/jbesclapez/docker-qbittorrent-nox.git
