#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Intelligent Docker Engine Installer (Online + Pure Offline)
# Compatible with Bash 3.2+ (macOS) and modern Linux
# Target: Ubuntu 26.04 (resolute) & Debian 13 / MX Linux 25 (trixie)
# Default architecture: amd64 (only downloads arm64 if user explicitly types "arm")
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}==============================================================${NC}"
echo -e "${CYAN}  Intelligent Docker Engine Installer (Online + Offline)${NC}"
echo -e "${CYAN}  Designed for Air-gapped & Sanctioned Environments${NC}"
echo -e "${CYAN}==============================================================${NC}"
echo

log_info()  { echo -e "${GREEN}→ $1${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠  $1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }
log_step()  { echo -e "${BLUE}[ $1 ]${NC}"; }

# --------------------------------------------------------------------------
# Architecture selection (Default = amd64)
# --------------------------------------------------------------------------
ARCH="amd64"

echo -e "${YELLOW}Architecture selection:${NC}"
echo -e "  Default is ${GREEN}amd64${NC} (recommended for most servers and desktops)"
echo -e "  Only type ${CYAN}arm${NC} if you really need arm64 packages"
echo
printf "Enter architecture [amd64] (type 'arm' for arm64, or just press Enter): "
read ARCH_INPUT

# Normalize input
ARCH_INPUT=$(echo "${ARCH_INPUT:-}" | tr '[:upper:]' '[:lower:]' | xargs)

if [ "$ARCH_INPUT" = "arm" ] || [ "$ARCH_INPUT" = "arm64" ] || [ "$ARCH_INPUT" = "aarch64" ]; then
  ARCH="arm64"
  log_warn "You explicitly selected arm64"
else
  ARCH="amd64"
  log_info "Using default architecture: amd64"
fi

echo

# --------------------------------------------------------------------------
# OS Detection + Interactive menu
# --------------------------------------------------------------------------
DOCKER_DIST=""
CODENAME=""
IS_SUPPORTED_LINUX=false
CURRENT_OS="unknown"

if [ -f /etc/os-release ]; then
  . /etc/os-release
  CURRENT_OS="$PRETTY_NAME"

  case "$ID" in
    ubuntu)
      DOCKER_DIST="ubuntu"
      CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
      IS_SUPPORTED_LINUX=true
      ;;
    debian|mx)
      DOCKER_DIST="debian"
      CODENAME="$VERSION_CODENAME"
      IS_SUPPORTED_LINUX=true
      ;;
  esac
else
  CURRENT_OS="$(uname -s) $(uname -r)"
fi

if [ -z "$DOCKER_DIST" ] || [ -z "$CODENAME" ]; then
  echo -e "${YELLOW}Could not automatically detect a supported Linux distribution.${NC}"
  echo -e "${YELLOW}Current system: ${CURRENT_OS}${NC}"
  echo
  echo "Please choose the target repository:"
  echo
  echo "  1) Ubuntu 26.04 (resolute)           ← Production Server"
  echo "  2) Debian 13 / MX Linux 25 (trixie)  ← Development Desktop"
  echo "  3) Enter custom values manually"
  echo
  printf "Enter your choice [1-3]: "
  read CHOICE

  case "$CHOICE" in
    1)
      DOCKER_DIST="ubuntu"
      CODENAME="resolute"
      ;;
    2)
      DOCKER_DIST="debian"
      CODENAME="trixie"
      ;;
    3)
      printf "Enter Docker distribution (ubuntu or debian): "
      read DOCKER_DIST
      printf "Enter codename (e.g. resolute, trixie): "
      read CODENAME
      DOCKER_DIST=$(echo "$DOCKER_DIST" | tr '[:upper:]' '[:lower:]')
      CODENAME=$(echo "$CODENAME" | tr '[:upper:]' '[:lower:]')
      ;;
    *)
      log_error "Invalid choice."
      exit 1
      ;;
  esac
fi

log_info "Selected Docker repository : $DOCKER_DIST"
log_info "Selected Codename          : $CODENAME"
log_info "Architecture               : $ARCH"
log_info "Current system             : $CURRENT_OS"
echo

# --------------------------------------------------------------------------
# Offline mode check
# --------------------------------------------------------------------------
OFFLINE_MODE=false
LOCAL_DIR=""

if [ "${1:-}" = "--offline" ] || [ "${1:-}" = "-o" ]; then
  OFFLINE_MODE=true
  LOCAL_DIR="${2:-.}"
elif [ -d "./docker-packages" ] && [ -f "./docker-packages/docker.gpg" ]; then
  OFFLINE_MODE=true
  LOCAL_DIR="./docker-packages"
  log_warn "Found existing docker-packages folder → switching to pure offline mode"
fi

# --------------------------------------------------------------------------
# Pure Offline Installation
# --------------------------------------------------------------------------
if [ "$OFFLINE_MODE" = true ]; then
  log_step "Pure Offline Mode Activated"
  echo

  if [ ! -d "$LOCAL_DIR" ]; then
    log_error "Local package directory not found: $LOCAL_DIR"
    exit 1
  fi

  cd "$LOCAL_DIR"
  log_info "Using packages from: $(pwd)"
  echo

  for pattern in docker.gpg containerd.io_*.deb docker-ce_*.deb docker-ce-cli_*.deb \
                 docker-buildx-plugin_*.deb docker-compose-plugin_*.deb; do
    if ! ls $pattern >/dev/null 2>&1; then
      log_error "Missing required file matching: $pattern"
      exit 1
    fi
  done

  if [ "$IS_SUPPORTED_LINUX" != true ]; then
    log_error "This system is not Ubuntu or Debian/MX Linux. Cannot install .deb packages."
    exit 1
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
# Online Mode - Download with fallback mirrors
# --------------------------------------------------------------------------
log_step "Online Mode – Downloading latest packages with fallback mirrors"
echo

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

WORKDIR="docker-offline-${DOCKER_DIST}-${CODENAME}-${ARCH}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
log_info "Working directory: $(pwd)"
echo

PACKAGES="containerd.io docker-ce-cli docker-ce docker-buildx-plugin docker-compose-plugin"
download_success=false

for MIRROR in $MIRRORS; do
  BASE_URL="${MIRROR}/${DOCKER_DIST}/dists/${CODENAME}/pool/stable/${ARCH}/"
  GPG_URL="${MIRROR}/${DOCKER_DIST}/gpg"

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

  # Find latest version of each package (Bash 3.2 compatible)
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
    if curl -fsSL --connect-timeout 20 -o "$file" "${BASE_URL}${file}"; then
      echo -e "${GREEN}OK${NC}"
    else
      echo -e "${RED}FAILED${NC}"
      download_ok=false
      break
    fi
  done

  if [ "$download_ok" = true ]; then
    download_success=true
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

# --------------------------------------------------------------------------
# Install only on supported Linux
# --------------------------------------------------------------------------
if [ "$IS_SUPPORTED_LINUX" = true ]; then
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
else
  log_warn "Current system is not Ubuntu or Debian/MX Linux."
  log_warn "Packages were downloaded only (installation skipped)."
fi

# --------------------------------------------------------------------------
# Create offline package folder + README
# --------------------------------------------------------------------------
OFFLINE_DIR="../docker-packages"
mkdir -p "$OFFLINE_DIR"
cp docker.gpg *.deb "$OFFLINE_DIR/" 2>/dev/null || true

cat > "$OFFLINE_DIR/README.md" << EOF
# Docker Offline Packages

**Generated on:** $(date)
**Target OS:** $DOCKER_DIST ($CODENAME)
**Architecture:** $ARCH
**Generated on system:** $CURRENT_OS

## Contents
- docker.gpg
- containerd.io_*.deb
- docker-ce_*.deb
- docker-ce-cli_*.deb
- docker-buildx-plugin_*.deb
- docker-compose-plugin_*.deb

## How to install on air-gapped Ubuntu / Debian / MX Linux

\`\`\`bash
sudo ./install-docker-smart.sh --offline /path/to/this/folder
\`\`\`

Or manually:
\`\`\`bash
sudo dpkg -i *.deb
sudo systemctl enable --now docker
sudo usermod -aG docker \$USER
\`\`\`
EOF

echo
echo -e "${GREEN}==============================================================${NC}"
echo -e "${GREEN}  Process completed successfully!${NC}"
echo -e "${GREEN}==============================================================${NC}"
echo
echo -e "${YELLOW}Summary:${NC}"
echo "  • Architecture used     : $ARCH"
echo "  • Packages saved in     : $OFFLINE_DIR"
echo "  • README.md created."
echo

if [ "$IS_SUPPORTED_LINUX" = true ]; then
  echo -e "${GREEN}Docker has been installed on this machine.${NC}"
  docker --version 2>/dev/null || true
  docker compose version 2>/dev/null || true
  echo
  echo -e "${YELLOW}Please log out and log back in (or reboot).${NC}"
else
  echo -e "${YELLOW}You are on macOS / non-Linux → packages were only downloaded.${NC}"
  echo "Copy the 'docker-packages' folder to your Ubuntu or MX Linux machine."
fi
echo
