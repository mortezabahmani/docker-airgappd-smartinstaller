# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-09-20

### Fixed
- CLI option parsing no longer crashes when a flag is given without its required argument (`--distro`, `--codename`, `--arch`, `--offline`). Clear error messages are shown instead.
- Architecture interactive prompt logic rewritten using an explicit `ARCH_SET_VIA_CLI` flag (removed fragile `$*` grep and undefined variable).
- Default architecture remains **amd64**; **arm64** is selected only when the user explicitly types `arm` / `arm64` / `aarch64`, or passes `--arch arm64`.

### Added
- `.gitignore` to keep temporary `docker-offline-*` directories and generated `docker-packages/` out of the repository.
- This `CHANGELOG.md` file; future releases will be recorded here.

### Changed
- Version bumped to `1.1.1`.
- Documentation (English and Persian) updated to reference the changelog and repository hygiene.

### Notes
- Pull Request #1 proposed similar script fixes but also committed temporary GPG/key directories. Those artifacts were **not** merged. Only the clean script fixes are included in this release.

## [1.1.0] - 2026-09-20

### Added
- Non-interactive mode: `--distro`, `--codename`, `--arch`, `--yes`.
- SHA256SUMS generation and optional verification in offline mode.
- Support for Ubuntu noble and Debian bookworm in addition to resolute/trixie.
- Automatic cleanup of temporary download directories (override with `--keep-temp`).
- Proxy awareness via standard `http_proxy` / `https_proxy` environment variables.
- `--list-mirrors`, `--dry-run`, `--skip-test`.
- Optional post-install `docker run hello-world` test with timeout.
- Bilingual documentation (`README.md` + `README-fa.md`).
- MIT License.

### Security
- Install path only runs on detected Ubuntu/Debian/MX systems.
- On macOS and other hosts, the tool only downloads and prepares the offline bundle.

## [1.0.0] - 2026-09-20

### Added
- Initial public structure of the air-gapped Docker installer.
- Multi-mirror download with fallback (official + university + regional mirrors).
- Interactive OS and architecture selection.
- Online download mode and pure offline install mode.
- Generation of a reusable `docker-packages/` folder for air-gapped transfer.
