# Docker Air-Gapped Smart Installer

**Intelligent, multi-mirror, offline-capable Docker Engine installer** designed for air-gapped environments and regions with network restrictions.

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/mortezabahmani/docker-airgappd-smartinstaller)
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

The offline folder contains:
- All required `.deb` packages
- Docker GPG key
- `SHA256SUMS` for integrity verification
- A small README with install instructions

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

You can list them anytime:

```bash
./install-docker-smart.sh --list-mirrors
```

---

## Integrity Verification

After download, a `SHA256SUMS` file is generated.

On the target machine you can verify before installation:

```bash
cd docker-packages
sha256sum -c SHA256SUMS
```

---

## Security Notes

- The script only installs packages when it detects a real Ubuntu or Debian-based system.
- On macOS and other systems it only downloads and prepares the offline bundle.
- GPG key is installed into `/etc/apt/keyrings` using modern practices.
- No `eval` is used on external data.
- Temporary directories are cleaned up by default.

---

## Requirements

- `bash` 3.2 or newer
- `curl`
- `dpkg` / `apt` (for installation on target)
- `sha256sum` (recommended for integrity checks)

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

**Built for reliable Docker Engine installation in restricted and air-gapped environments.**
