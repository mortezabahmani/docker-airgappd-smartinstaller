# Docker Air-Gapped Smart Installer

**Intelligent, multi-mirror, offline-capable Docker Engine installer** designed for air-gapped environments and regions affected by network restrictions or sanctions.

> Specially built for reliable Docker installation on **Ubuntu 26.04 LTS (resolute)** and **Debian 13 / MX Linux 25 (trixie)**.

---

## Features

- **Dual Mode Operation**
  - **Online Mode**: Automatically downloads the latest Docker Engine packages from multiple mirrors with intelligent fallback.
  - **Pure Offline Mode**: Installs from a previously prepared package folder without any internet access.

- **Smart Detection**
  - Automatically detects Ubuntu or Debian/MX Linux.
  - Interactive menu when running on macOS or unsupported systems.

- **Architecture Handling**
  - Defaults to **amd64** (recommended for most servers and desktops).
  - Downloads **arm64** packages only if the user explicitly types `arm`.

- **Multi-Mirror Fallback**
  - Official Docker repository
  - Multiple Chinese university mirrors (Tsinghua, USTC, PKU, Aliyun, Tencent)
  - Iranian mirrors as last resort

- **Air-Gapped Ready**
  - Creates a clean `docker-packages/` folder containing all `.deb` files + GPG key + README.
  - Perfect for transferring to isolated production servers.

- **Bash 3.2 Compatible**
  - Works on macOS default Bash as well as modern Linux systems.

---

## Supported Targets

| Distribution              | Codename  | Recommended Use          |
|---------------------------|-----------|--------------------------|
| Ubuntu 26.04 LTS          | resolute  | Production Server        |
| Debian 13 / MX Linux 25   | trixie    | Development Desktop      |

---

## Quick Start

### 1. Download the script

```bash
curl -fsSL -o install-docker-smart.sh \
  https://raw.githubusercontent.com/mortezabahmani/docker-airgappd-smartinstaller/main/install-docker-smart.sh

chmod +x install-docker-smart.sh
```

> Note: Since this is a private repository, you may need to authenticate or download the file manually from GitHub.

### 2. Run the installer

```bash
./install-docker-smart.sh
```

The script will:

1. Ask for architecture (just press **Enter** for amd64).
2. Detect the OS or ask you to choose Ubuntu / Debian.
3. Download the latest packages using the best available mirror.
4. Install Docker if running on a supported Linux system.
5. Create a reusable offline package folder.

---

## Usage Modes

### Online Mode (Default)

```bash
./install-docker-smart.sh
```

### Pure Offline Mode

After you have prepared the packages on a machine with internet:

```bash
sudo ./install-docker-smart.sh --offline /path/to/docker-packages
```

---

## Recommended Workflow (Air-Gapped Deployment)

1. **On a machine with internet** (can be macOS or Linux):

   ```bash
   ./install-docker-smart.sh
   ```

   - Choose architecture (default amd64)
   - Choose target OS (Ubuntu 26.04 or Debian/MX)
   - Let it download the packages

2. **Copy the generated folder** to the target air-gapped machine:

   ```bash
   scp -r docker-packages/ user@airgapped-server:/tmp/
   ```

3. **On the air-gapped machine**:

   ```bash
   cd /tmp/docker-packages
   sudo /path/to/install-docker-smart.sh --offline .
   ```

---

## What Gets Downloaded

The script downloads the latest versions of:

- `containerd.io`
- `docker-ce`
- `docker-ce-cli`
- `docker-buildx-plugin`
- `docker-compose-plugin`
- Official Docker GPG key

---

## Mirror Priority

1. Official Docker (`download.docker.com`)
2. Tsinghua University
3. USTC
4. Peking University
5. Aliyun
6. Tencent Cloud
7. ArvanCloud (Iran)
8. IranServer (Iran)

---

## Notes

- After installation, log out and log back in (or reboot) so that the `docker` group membership takes effect.
- The script is intentionally conservative: it only installs packages when running on a real Ubuntu or Debian/MX system.
- On macOS it only downloads the packages and prepares the offline folder.

---

## License

MIT License – feel free to use and modify for your air-gapped deployments.

---

**Maintained for reliable Docker installation in restricted network environments.**
