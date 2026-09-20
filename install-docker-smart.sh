#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Docker Air-Gapped Smart Installer
# Intelligent offline-capable Docker Engine installer with multi-mirror fallback
# Compatible with Bash 3.2+ (macOS) and modern Linux
# =============================================================================

VERSION="1.1.1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}→ $1${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠  $1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }
log_step()  { echo -e "${BLUE}[ $1 ]${NC}"; }

usage() {
  cat << EOF
Docker Air-Gapped Smart Installer v${VERSION}

Usage:
  $0 [OPTIONS]

Options:
  --distro <ubuntu|debian>     Target distribution
  --codename <name>            Codename (resolute, trixie, noble, bookworm, ...)
  --arch <amd64|arm64>         Architecture (default: amd64)
  --offline <dir>              Pure offline install from directory
  --yes, -y                    Non-interactive mode (assume defaults / provided values)
  --dry-run                    Show what would be done without making changes
  --list-mirrors               List configured mirrors and exit
  --skip-test                  Skip post-install hello-world test
  --keep-temp                  Do not remove temporary download directory
  --help, -h                   Show this help

Examples:
  $0
  $0 --distro ubuntu --codename resolute --arch amd64 --yes
  $0 --offline ./docker-packages
  $0 --list-mirrors

EOF
  exit 0
}

# --------------------------------------------------------------------------
# Defaults & argument parsing
# --------------------------------------------------------------------------
DISTRO=""
CODENAME=""
ARCH="amd64"
OFFLINE_MODE=false
OFFLINE_DIR=""
NON_INTERACTIVE=false
DRY_RUN=false
LIST_MIRRORS=false
SKIP_TEST=false
KEEP_TEMP=false
ARCH_SET_VIA_CLI=false

while [ $# -gt 0 ]; do
  case "$1" in
    --distro)
      [ $# -gt 1 ] || { log_error "Option --distro requires an argument"; exit 1; }
      DISTRO="$2"; shift 2 ;;
    --codename)
      [ $# -gt 1 ] || { log_error "Option --codename requires an argument"; exit 1; }
      CODENAME="$2"; shift 2 ;;
    --arch)
      [ $# -gt 1 ] || { log_error "Option --arch requires an argument"; exit 1; }
      ARCH="$2"; ARCH_SET_VIA_CLI=true; shift 2 ;;
    --offline|-o)
      [ $# -gt 1 ] || { log_error "Option --offline requires an argument"; exit 1; }
      OFFLINE_MODE=true; OFFLINE_DIR="$2"; shift 2 ;;
    --yes|-y)      NON_INTERACTIVE=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --list-mirrors) LIST_MIRRORS=true; shift ;;
    --skip-test)   SKIP_TEST=true; shift ;;
    --keep-temp)   KEEP_TEMP=true; shift ;;
    --help|-h)     usage ;;
    *) log_error "Unknown option: $1"; usage ;;
  esac
done

# Normalize
DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
CODENAME=$(echo "$CODENAME" | tr '[:upper:]' '[:lower:]')
ARCH=$(echo "$ARCH" | tr '[:upper:]' '[:lower:]')

case "$ARCH" in
  amd64|arm64) ;;
  arm|aarch64) ARCH="arm64" ;;
  *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# --------------------------------------------------------------------------
# Mirrors
# --------------------------------------------------------------------------
MIRRORS="
https://download.docker.com/linux
https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux
https://mirrors.ustc.edu.cn/docker-ce/linux
https://mirrors.pku.edu.cn/docker-ce/linux
https://mirrors.aliyun.com/docker-ce/linux
https://mirrors.cloud.tencent.com/docker-ce/linux
https://mirror.arvancloud.ir/docker-ce/linux
https://mirrors.iranserver.com/docker-ce/linux
"

if [ "$LIST_MIRRORS" = true ]; then
  echo "Configured mirrors (in priority order):"
  i=1
  for m in $MIRRORS; do
    echo "  $i. $m"
    i=$((i+1))
  done
  exit 0
fi

echo -e "${CYAN}==============================================================${NC}"
echo -e "${CYAN}  Docker Air-Gapped Smart Installer v${VERSION}${NC}"
echo -e "${CYAN}  Multi-mirror • Offline-capable • Sanction-friendly${NC}"
echo -e "${CYAN}==============================================================${NC}"
echo

if [ "$DRY_RUN" = true ]; then
  log_warn "DRY-RUN mode enabled — no changes will be made"
  echo
fi

# --------------------------------------------------------------------------
# Proxy support
# --------------------------------------------------------------------------
if [ -n "${https_proxy:-}${HTTPS_PROXY:-}${http_proxy:-}${HTTP_PROXY:-}" ]; then
  log_info "Proxy environment variables detected — curl will use them"
fi

# --------------------------------------------------------------------------
# Architecture interactive selection (only if not provided via CLI)
# --------------------------------------------------------------------------
if [ "$ARCH_SET_VIA_CLI" = false ] && [ "$NON_INTERACTIVE" = false ]; then
  echo -e "${YELLOW}Architecture selection:${NC}"
  echo -e "  Default is ${GREEN}amd64${NC} (recommended for most servers and desktops)"
  echo -e "  Only type ${CYAN}arm${NC} if you really need arm64 packages"
  echo
  printf "Enter architecture [amd64] (type 'arm' for arm64, or just press Enter): "
  read ARCH_INPUT
  ARCH_INPUT=$(echo "${ARCH_INPUT:-}" | tr '[:upper:]' '[:lower:]' | xargs)
  if [ "$ARCH_INPUT" = "arm" ] || [ "$ARCH_INPUT" = "arm64" ] || [ "$ARCH_INPUT" = "aarch64" ]; then
    ARCH="arm64"
    log_warn "You explicitly selected arm64"
  else
    ARCH="amd64"
    log_info "Using default architecture: amd64"
  fi
  echo
fi

# --------------------------------------------------------------------------
# OS Detection
# --------------------------------------------------------------------------
IS_SUPPORTED_LINUX=false
CURRENT_OS="unknown"

if [ -f /etc/os-release ]; then
  . /etc/os-release
  CURRENT_OS="$PRETTY_NAME"

  case "$ID" in
    ubuntu)
      if [ -z "$DISTRO" ]; then DISTRO="ubuntu"; fi
      if [ -z "$CODENAME" ]; then CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"; fi
      IS_SUPPORTED_LINUX=true
      ;;
    debian|mx)
      if [ -z "$DISTRO" ]; then DISTRO="debian"; fi
      if [ -z "$CODENAME" ]; then CODENAME="$VERSION_CODENAME"; fi
      IS_SUPPORTED_LINUX=true
      ;;
  esac
else
  CURRENT_OS="$(uname -s) $(uname -r)"
fi

# Interactive selection if still missing
if [ -z "$DISTRO" ] || [ -z "$CODENAME" ]; then
  if [ "$NON_INTERACTIVE" = true ]; then
    log_error "Non-interactive mode requires --distro and --codename"
    exit 1
  fi

  echo -e "${YELLOW}Could not automatically detect a supported Linux distribution.${NC}"
  echo -e "${YELLOW}Current system: ${CURRENT_OS}${NC}"
  echo
  echo "Please choose the target repository:"
  echo
  echo "  1) Ubuntu 26.04 (resolute)           ← Production Server"
  echo "  2) Debian 13 / MX Linux 25 (trixie)  ← Development Desktop"
  echo "  3) Ubuntu 24.04 (noble)"
  echo "  4) Debian 12 (bookworm)"
  echo "  5) Enter custom values manually"
  echo
  printf "Enter your choice [1-5]: "
  read CHOICE

  case "$CHOICE" in
    1) DISTRO="ubuntu"; CODENAME="resolute" ;;
    2) DISTRO="debian"; CODENAME="trixie" ;;
    3) DISTRO="ubuntu"; CODENAME="noble" ;;
    4) DISTRO="debian"; CODENAME="bookworm" ;;
    5)
      printf "Enter Docker distribution (ubuntu or debian): "
      read DISTRO
      printf "Enter codename: "
      read CODENAME
      DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
      CODENAME=$(echo "$CODENAME" | tr '[:upper:]' '[:lower:]')
      ;;
    *) log_error "Invalid choice."; exit 1 ;;
  esac
fi

log_info "Selected Docker repository : $DISTRO"
log_info "Selected Codename          : $CODENAME"
log_info "Architecture               : $ARCH"
log_info "Current system             : $CURRENT_OS"
echo

# --------------------------------------------------------------------------
# Pure Offline Installation
# --------------------------------------------------------------------------
if [ "$OFFLINE_MODE" = true ]; then
  log_step "Pure Offline Mode Activated"
  echo

  if [ ! -d "$OFFLINE_DIR" ]; then
    log_error "Local package directory not found: $OFFLINE_DIR"
    exit 1
  fi

  cd "$OFFLINE_DIR"
  log_info "Using packages from: $(pwd)"
  echo

  for pattern in docker.gpg containerd.io_*.deb docker-ce_*.deb docker-ce-cli_*.deb \
                 docker-buildx-plugin_*.deb docker-compose-plugin_*.deb; do
    if ! ls $pattern >/dev/null 2>&1; then
      log_error "Missing required file matching: $pattern"
      exit 1
    fi
  done

  # Optional SHA256 verification
  if [ -f SHA256SUMS ]; then
    log_step "Verifying SHA256 checksums..."
    if command -v sha256sum >/dev/null 2>&1; then
      if sha256sum -c SHA256SUMS --ignore-missing; then
        log_info "Checksums verified successfully"
      else
        log_error "Checksum verification failed"
        exit 1
      fi
    else
      log_warn "sha256sum not available — skipping checksum verification"
    fi
  fi

  if [ "$IS_SUPPORTED_LINUX" != true ]; then
    log_error "This system is not Ubuntu or Debian/MX Linux. Cannot install .deb packages."
    exit 1
  fi

  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Would install packages and enable docker service"
    exit 0
  fi

  log_step "Removing conflicting packages..."
  sudo apt-get remove -y \
    docker.io docker-doc docker-compose docker-compose-v2 \
    docker-buildx podman-docker containerd runc 2>/dev/null || true

  log_step "Installing GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo cp docker.gpg /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  log_step "Installing Docker packages..."
  sudo dpkg -i \
    containerd.io_*.deb \
    docker-ce-cli_*.deb \
    docker-ce_*.deb \
    docker-buildx-plugin_*.deb \
    docker-compose-plugin_*.deb

  sudo apt-get install -f -y || true

  log_step "Enabling Docker service..."
  sudo systemctl enable docker
  sudo systemctl start docker

  REAL_USER="${SUDO_USER:-$USER}"
  if id "$REAL_USER" >/dev/null 2>&1; then
    sudo usermod -aG docker "$REAL_USER"
    log_info "User '$REAL_USER' added to docker group"
  fi

  echo
  echo -e "${GREEN}==============================================================${NC}"
  echo -e "${GREEN}  Offline installation completed successfully!${NC}"
  echo -e "${GREEN}==============================================================${NC}"
  docker --version
  docker compose version
  echo
  echo -e "${YELLOW}Please log out and log back in (or reboot).${NC}"
  exit 0
fi

# --------------------------------------------------------------------------
# Online Mode - Download
# --------------------------------------------------------------------------
log_step "Online Mode – Downloading latest packages with fallback mirrors"
echo

WORKDIR="docker-offline-${DISTRO}-${CODENAME}-${ARCH}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
log_info "Working directory: $(pwd)"
echo

PACKAGES="containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin"
download_success=false
USED_MIRROR=""

for MIRROR in $MIRRORS; do
  BASE_URL="${MIRROR}/${DISTRO}/dists/${CODENAME}/pool/stable/${ARCH}/"
  GPG_URL="${MIRROR}/${DISTRO}/gpg"

  log_info "Trying mirror: $MIRROR"

  if ! curl -fsSL --connect-timeout 8 --max-time 15 "$BASE_URL" -o /dev/null 2>/dev/null; then
    log_warn "Mirror unreachable → skipping"
    continue
  fi

  if ! curl -fsSL --connect-timeout 10 "$GPG_URL" -o docker.gpg 2>/dev/null; then
    log_warn "Failed to download GPG key → trying next mirror"
    continue
  fi

  INDEX=$(curl -fsSL --connect-timeout 10 "$BASE_URL" 2>/dev/null || true)
  if [ -z "$INDEX" ]; then
    log_warn "Empty package index → trying next mirror"
    continue
  fi

  LATEST_containerd=""
  LATEST_cli=""
  LATEST_ce=""
  LATEST_buildx=""
  LATEST_compose=""

  for pkg in $PACKAGES; do
    latest=$(echo "$INDEX" | grep -oE "${pkg}_[0-9][^\"<> ]+_${ARCH}\.deb" | sort -V | tail -1 || true)
    case "$pkg" in
      containerd.io)          LATEST_containerd="$latest" ;;
      docker-ce-cli)          LATEST_cli="$latest" ;;
      docker-ce)              LATEST_ce="$latest" ;;
      docker-buildx-plugin)   LATEST_buildx="$latest" ;;
      docker-compose-plugin)  LATEST_compose="$latest" ;;
    esac
  done

  if [ -z "$LATEST_containerd" ] || [ -z "$LATEST_cli" ] || [ -z "$LATEST_ce" ] || \
     [ -z "$LATEST_buildx" ] || [ -z "$LATEST_compose" ]; then
    log_warn "Could not resolve all packages → trying next mirror"
    continue
  fi

  log_info "Downloading packages for ${ARCH}..."
  download_ok=true

  for file in "$LATEST_containerd" "$LATEST_cli" "$LATEST_ce" "$LATEST_buildx" "$LATEST_compose"; do
    echo -n "   → $file ... "
    if [ "$DRY_RUN" = true ]; then
      echo -e "${YELLOW}DRY-RUN${NC}"
    else
      if curl -fsSL --connect-timeout 20 -o "$file" "${BASE_URL}${file}"; then
        echo -e "${GREEN}OK${NC}"
      else
        echo -e "${RED}FAILED${NC}"
        download_ok=false
        break
      fi
    fi
  done

  if [ "$download_ok" = true ]; then
    download_success=true
    USED_MIRROR="$MIRROR"
    log_info "Successfully downloaded from: $MIRROR"
    break
  else
    rm -f ./*.deb docker.gpg 2>/dev/null || true
  fi
done

if [ "$download_success" != true ]; then
  log_error "All mirrors failed. Cannot download Docker packages."
  exit 1
fi

echo
log_step "Packages downloaded successfully."

# Generate SHA256SUMS
if [ "$DRY_RUN" = false ]; then
  log_step "Generating SHA256SUMS..."
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum docker.gpg *.deb > SHA256SUMS
    log_info "SHA256SUMS created"
  else
    log_warn "sha256sum not available — checksum file not generated"
  fi
fi

# --------------------------------------------------------------------------
# Install only on supported Linux
# --------------------------------------------------------------------------
if [ "$IS_SUPPORTED_LINUX" = true ] && [ "$DRY_RUN" = false ]; then
  log_step "Supported Linux detected → Installing Docker..."

  sudo apt-get remove -y \
    docker.io docker-doc docker-compose docker-compose-v2 \
    docker-buildx podman-docker containerd runc 2>/dev/null || true

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo cp docker.gpg /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  sudo dpkg -i \
    containerd.io_*.deb \
    docker-ce-cli_*.deb \
    docker-ce_*.deb \
    docker-buildx-plugin_*.deb \
    docker-compose-plugin_*.deb

  sudo apt-get install -f -y || true

  sudo systemctl enable docker
  sudo systemctl start docker

  REAL_USER="${SUDO_USER:-$USER}"
  if id "$REAL_USER" >/dev/null 2>&1; then
    sudo usermod -aG docker "$REAL_USER"
    log_info "User '$REAL_USER' added to docker group"
  fi

  # Post-install test
  if [ "$SKIP_TEST" = false ]; then
    log_step "Running post-install test (hello-world)..."
    if timeout 30 docker run --rm hello-world >/dev/null 2>&1; then
      log_info "Post-install test passed"
    else
      log_warn "Post-install test failed or timed out (this is OK on restricted networks)"
    fi
  fi
else
  if [ "$IS_SUPPORTED_LINUX" != true ]; then
    log_warn "Current system is not Ubuntu or Debian/MX Linux."
    log_warn "Packages were downloaded only (installation skipped)."
  fi
fi

# --------------------------------------------------------------------------
# Create offline package folder
# --------------------------------------------------------------------------
FINAL_DIR="../docker-packages"
mkdir -p "$FINAL_DIR"

if [ "$DRY_RUN" = false ]; then
  cp docker.gpg *.deb SHA256SUMS "$FINAL_DIR/" 2>/dev/null || true

  cat > "$FINAL_DIR/README.md" << EOF
# Docker Offline Packages

**Generated on:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Installer version:** ${VERSION}
**Target OS:** $DISTRO ($CODENAME)
**Architecture:** $ARCH
**Source mirror:** $USED_MIRROR
**Generated on system:** $CURRENT_OS

## Contents
- docker.gpg
- containerd.io_*.deb
- docker-ce_*.deb
- docker-ce-cli_*.deb
- docker-buildx-plugin_*.deb
- docker-compose-plugin_*.deb
- SHA256SUMS

## Verify integrity

\`\`\`bash
sha256sum -c SHA256SUMS
\`\`\`

## Install on air-gapped machine

\`\`\`bash
sudo ./install-docker-smart.sh --offline /path/to/this/folder
\`\`\`
EOF

  log_info "Offline package folder created: $FINAL_DIR"
fi

# Cleanup temp directory
if [ "$KEEP_TEMP" = false ] && [ "$DRY_RUN" = false ]; then
  cd ..
  rm -rf "$WORKDIR"
  log_info "Temporary directory cleaned up"
fi

echo
echo -e "${GREEN}==============================================================${NC}"
echo -e "${GREEN}  Process completed successfully!${NC}"
echo -e "${GREEN}==============================================================${NC}"
echo
echo -e "${YELLOW}Summary:${NC}"
echo "  • Architecture used     : $ARCH"
echo "  • Target               : $DISTRO ($CODENAME)"
echo "  • Packages saved in    : $FINAL_DIR"
echo "  • SHA256SUMS generated : yes"
echo

if [ "$IS_SUPPORTED_LINUX" = true ] && [ "$DRY_RUN" = false ]; then
  echo -e "${GREEN}Docker has been installed on this machine.${NC}"
  docker --version 2>/dev/null || true
  docker compose version 2>/dev/null || true
  echo
  echo -e "${YELLOW}Please log out and log back in (or reboot) for group changes.${NC}"
else
  echo -e "${YELLOW}Packages were prepared for offline use.${NC}"
  echo "Copy the 'docker-packages' folder to your target Linux machine."
fi
echo
