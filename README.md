# Docker Air-Gapped Smart Installer

**Intelligent, multi-mirror, offline-capable Docker Engine installer** designed for air-gapped environments and regions with network restrictions.

[![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> 📖 **نسخه فارسی مستندات در دسترس است** → [README-fa.md](README-fa.md)

---

## Features

| Feature | Description |
|---------|-------------|
| **Dual Mode** | Online download with multi-mirror fallback + Pure offline installation |
| **Non-Interactive** | Fully scriptable with `--distro`, `--codename`, `--arch`, `--yes` |
| **Integrity** | Generates and verifies `SHA256SUMS` |
| **Multi-Arch** | Defaults to `amd64`, supports `arm64` on explicit request |
| **Multi-Distro** | Ubuntu (resolute, noble, ...) and Debian (trixie, bookworm, ...) |
| **Proxy Aware** | Respects `http_proxy` / `https_proxy` environment variables |
| **Dry-Run** | `--dry-run` mode to preview actions |
| **Post-Install Test** | Optional `docker run hello-world` verification |
| **Bash 3.2+** | Works on macOS default Bash and modern Linux |

---

## Supported Targets

| Distribution | Codename | Typical Use |
|--------------|----------|-------------|
| Ubuntu 26.04 LTS | `resolute` | Production servers |
| Ubuntu 24.04 LTS | `noble` | Production / LTS environments |
| Debian 13 | `trixie` | Development desktops (e.g. MX Linux 25) |
| Debian 12 | `bookworm` | Stable servers |

---

## Quick Start

```bash
chmod +x install-docker-smart.sh
./install-docker-smart.sh
```

The script will guide you interactively.

### Non-Interactive Example

```bash
./install-docker-smart.sh \
  --distro ubuntu \
  --codename resolute \
  --arch amd64 \
  --yes
```

### Pure Offline Install

```bash
sudo ./install-docker-smart.sh --offline /path/to/docker-packages
```

---

## Command Line Options

```
--distro <ubuntu|debian>     Target distribution
--codename <name>            Codename (resolute, trixie, noble, bookworm, ...)
--arch <amd64|arm64>         Architecture (default: amd64)
--offline <dir>              Pure offline install from directory
--yes, -y                    Non-interactive mode
--dry-run                    Show actions without executing them
--list-mirrors               List configured mirrors and exit
--skip-test                  Skip post-install hello-world test
--keep-temp                  Keep temporary download directory
--help, -h                   Show help
```

---

## Recommended Air-Gapped Workflow

1. **On a machine with internet access** (macOS or Linux):

   ```bash
   ./install-docker-smart.sh --distro ubuntu --codename resolute --arch amd64 --yes
   ```

2. **Transfer the generated folder**:

   ```bash
   scp -r docker-packages/ user@airgapped-host:/opt/
   ```

3. **On the air-gapped machine**:

   ```bash
   sudo ./install-docker-smart.sh --offline /opt/docker-packages
   ```

The offline folder contains all required `.deb` packages, the Docker GPG key, `SHA256SUMS`, and a small README.

> **Note:** Do not commit `docker-packages/` or `docker-offline-*/` directories to git. They are listed in `.gitignore`.

---

## Mirror Priority

1. Official Docker (`download.docker.com`)
2. Tsinghua University
3. University of Science and Technology of China (USTC)
4. Peking University
5. Aliyun
6. Tencent Cloud
7. ArvanCloud
8. IranServer

```bash
./install-docker-smart.sh --list-mirrors
```

---

## Integrity Verification

```bash
cd docker-packages
sha256sum -c SHA256SUMS
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

## Security Notes

- Packages are installed only when a real Ubuntu or Debian-based system is detected.
- On macOS and other systems the tool only downloads and prepares the offline bundle.
- GPG key is installed under `/etc/apt/keyrings`.
- No `eval` is used on external data.
- Temporary directories are removed by default.

---

## Requirements

- `bash` 3.2 or newer
- `curl`
- `dpkg` / `apt` (on the install target)
- `sha256sum` (recommended)

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

**Built for reliable Docker Engine installation in restricted and air-gapped environments.**
