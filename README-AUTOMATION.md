# 🚀 Automated qBittorrent-nox GhostTrackers Build System

This repository provides a fully automated build system for qBittorrent-nox with GhostTrackers libtorrent integration using GitHub Actions.

## ✨ Features

- **🤖 Fully Automated**: Build and publish Docker images via GitHub Actions
- **⚡ Fast Builds**: Uses pre-built libtorrent artifacts when available
- **🔧 Version Customizable**: Specify any qBittorrent version tag
- **🐳 Multi-Architecture**: Supports AMD64 and ARM64
- **📦 GitHub Container Registry**: Automatically publishes to `ghcr.io`
- **🏷️ Smart Tagging**: Version-based and latest tags
- **👻 GhostTrackers Integration**: Shows custom version in qBittorrent About page

## 🎯 Quick Start

### 1. Trigger a Build via GitHub Actions

1. Go to **Actions** tab in your GitHub repository
2. Select **"Build and Push qBittorrent-nox GhostTrackers"** workflow
3. Click **"Run workflow"**
4. Configure the parameters:
   - **qBittorrent version**: `release-5.1.2` (or any tag from [qBittorrent releases](https://github.com/qbittorrent/qBittorrent/tags))
   - **Libtorrent artifact URL**: `https://github.com/jbesclapez/libtorrent/actions/runs/16276276484/artifacts/3529935533`
   - **Image tag**: `5.1.2-ghostrackers` (optional, auto-generated if empty)
   - **Tag as latest**: ☑️ (optional)

5. Click **"Run workflow"** to start the build

### 2. Use the Pre-built Image

Once the build completes, you can use the image directly:

```bash
# Pull the image
docker pull ghcr.io/yourusername/docker-qbittorrent-nox-ghostracker:5.1.2-ghostrackers

# Run with Docker
docker run -d \
  --name qbittorrent-ghostrackers \
  -e QBT_LEGAL_NOTICE=confirm \
  -e QBT_WEBUI_PORT=8085 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Paris \
  -p 8085:8085 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -v ./config:/config \
  -v ./downloads:/downloads \
  ghcr.io/yourusername/docker-qbittorrent-nox-ghostracker:5.1.2-ghostrackers
```

### 3. Use with Docker Compose

1. Copy `env.example` to `.env` and customize:
```bash
cp env.example .env
# Edit .env with your preferences
```

2. Update docker-compose.yml to use the pre-built image:
```yaml
services:
  qbittorrent-nox-ghostrackers:
    image: ghcr.io/yourusername/docker-qbittorrent-nox-ghostracker:5.1.2-ghostrackers
    # Remove the 'build' section when using pre-built images
```

3. Start the container:
```bash
docker-compose up -d
```

## 🛠️ Build Configuration

### GitHub Actions Workflow Inputs

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `qbt_version` | qBittorrent version tag (e.g., `release-5.1.2`) | `release-5.1.2` | ✅ |
| `libtorrent_artifact_url` | URL to pre-built libtorrent artifacts | [GhostTrackers build](https://github.com/jbesclapez/libtorrent/actions/runs/16276276484/artifacts/3529935533) | ✅ |
| `image_tag` | Custom Docker image tag | Auto-generated | ❌ |
| `latest_tag` | Also tag as 'latest' | `false` | ❌ |

### Available qBittorrent Versions

You can use any qBittorrent release tag from: https://github.com/qbittorrent/qBittorrent/tags

Popular versions:
- `release-5.1.2` (Latest stable)
- `release-5.1.1`
- `release-5.1.0`
- `release-5.0.3`
- `release-4.6.7` (LTS)

### Libtorrent Artifacts

The system uses pre-built GhostTrackers libtorrent from your GitHub Actions:
- **Source**: https://github.com/jbesclapez/libtorrent
- **Artifact URL**: https://github.com/jbesclapez/libtorrent/actions/runs/16276276484/artifacts/3529935533
- **SHA256**: `5189e826fda39153ced148686860a234e2c6bedcd770f023475f80fd6b92fe10`

## 🔄 Automated Triggers

The workflow automatically triggers on:

1. **Manual Workflow Dispatch** (preferred method)
2. **Push to main/GhostTracker-qbitorrent-nox branches** when these files change:
   - `Dockerfile`
   - `.github/workflows/build-and-publish.yml`
   - `entrypoint.sh`

## 📋 Build Process

1. **Checkout** repository code
2. **Setup** Docker Buildx for multi-platform builds
3. **Login** to GitHub Container Registry
4. **Extract** version information from inputs
5. **Build** Docker image with:
   - GhostTrackers libtorrent (pre-built or from source)
   - Custom qBittorrent version
   - Version patching to show "X.X.X GhostTrackers"
6. **Push** to `ghcr.io` with proper tags
7. **Generate** build summary with usage instructions

## 🏷️ Image Tagging Strategy

Images are tagged as:
- `{version}-ghostrackers` (e.g., `5.1.2-ghostrackers`)
- `latest` (if enabled)

With metadata labels:
- `org.opencontainers.image.version`
- `qbittorrent.version`
- `libtorrent.variant=ghostrackers`

## 🌐 Access Your Application

After deployment:
1. **Web UI**: `http://your-server:8085`
2. **Default credentials**:
   - Username: `admin`
   - Password: Check logs with `docker logs container-name`
3. **Version verification**: Check About page shows "X.X.X GhostTrackers"

## 🔧 Local Development

For local builds and testing:

```bash
# Clone the repository
git clone https://github.com/yourusername/docker-qbittorrent-nox-ghostracker.git
cd docker-qbittorrent-nox-ghostracker

# Copy and edit environment file
cp env.example .env
# Edit .env with your preferences

# Build locally
docker-compose build

# Run locally
docker-compose up -d
```

## 🐛 Troubleshooting

### Build Issues

1. **Artifact download fails**: The build automatically falls back to building libtorrent from source
2. **Version not found**: Ensure the qBittorrent version tag exists in the official repository
3. **Permission issues**: Check PUID/PGID values match your system user

### Runtime Issues

1. **Web UI not accessible**: Check firewall settings and port configuration
2. **Downloads fail**: Verify volume mounts and permissions
3. **Version not showing**: Check build logs for patching errors

### Logs and Debugging

```bash
# Check container logs
docker logs qbittorrent-nox-ghostrackers

# Check build logs in GitHub Actions
# Go to Actions tab → Select workflow run → View logs

# Verify image labels
docker inspect ghcr.io/yourusername/docker-qbittorrent-nox-ghostracker:5.1.2-ghostrackers
```

## 📝 Version History

The build system automatically generates a Software Bill of Materials (SBOM) containing:
- Boost version
- libtorrent GhostTrackers commit hash
- qBittorrent version
- Alpine Linux packages
- Build timestamp

View SBOM: `docker run --rm image-name cat /sbom.txt`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

This project maintains the same license as the original qBittorrent Docker project.

## 🔗 Related Links

- [qBittorrent Official](https://www.qbittorrent.org/)
- [qBittorrent Docker Hub](https://hub.docker.com/r/qbittorrentofficial/qbittorrent-nox)
- [GhostTrackers libtorrent](https://github.com/jbesclapez/libtorrent)
- [Original qBittorrent Docker](https://github.com/qbittorrent/docker-qbittorrent-nox) 