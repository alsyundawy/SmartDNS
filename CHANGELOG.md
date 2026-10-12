# Changelog

All notable changes to SmartDNS are documented in this file.

## [1.0.3-shellcheck-optimizer] - 2026-10-12

### Added

- SmartDNS Management Web UI on port 5000 (`ui/` module with systemd service `smartdns-ui.service`).
- System overview and real-time hardware monitoring (CPU, RAM, swap, disk I/O, network traffic PPS).
- Live DNS analytics, query logs, blocklist search, and DNS test suite in Web UI.
- System journal usage and retention optimization (`engine/sysctl.sh`: 200MB limit, 7-day retention).
- Dedicated feature updater engine (`engine/update.sh`) managing blocklist, schedulers, and UI installation.
- Integrated `cron` and `git` into core prerequisite package list.
- Integrated MegaLinter GitHub Action runner (`.github/workflows/megalinter.yml`) utilizing `oxsecurity/megalinter@v8`.
- Added repository-tailored MegaLinter configuration (`.mega-linter.yml`) with Microsoft DevSkim explicitly disabled (`DISABLE_LINTERS: [REPOSITORY_DEVSKIM]`).

### Enhanced & Hardened (13-Pillar Production Code Review)

- **13-Pillar Architecture & Security Audit**: Audited Bug, Syntax, Runtime, Logic, Memory, Dead Code, Deduplication, Circular Dependencies, Performance, Security Hardening, Maintainability, Scalability, and Readability across the entire repository.
- **Trunk Universal Linter**: 100% clean across all 55 files (`actionlint`, `checkov`, `git-diff-check`, `markdownlint`, `prettier`, `shellcheck`, `shfmt`, `trufflehog`, `yamllint`).
- **HTTP / RFC 7231 Compliance**: Enforced header-only responses for `do_HEAD` in Python server (`ui/server.py`), preventing broken pipe exceptions and body leaks.
- **Subprocess Hardening**: Removed `shell=True` invocation in background update runners in `ui/server.py`, passing argument lists directly to eliminate shell injection attack surfaces (CWE-78 / OWASP A05).
- **ShellCheck Compliance**: Fixed SC2249 (unhandled case branches), SC2310 (function invocation in conditionals), and SC2312 (subshell return masking) in `ui/install-local.sh` and `data/update-blocklist.sh`.
- **YAML & Formatting Standards**: Cleaned up quotes in `_config.yml` and `.mega-linter.yml` (yamllint) and standardized code formatting across markdown, shell, python, javascript, css, and html.
- **Resilient Blocklist Reload**: Guarded `dnsdist` live configuration reloads in `data/update-blocklist.sh` with active service checks.
- **Telemetry UUID Synchronization**: Enhanced telemetry UUID migration, validation routines, and fallback generation in `lib/telemetry.sh`.

## [1.0.2] - 2026-08-30

- Synchronized telemetry heartbeat and UUID handling across system updates.
- Added systemd journal retention limits.

## [1.0.1-shellcheck-optimizer] - 2026-08-15

- Released full ShellCheck compliance and strict bash standards.
- Added Automatic Update Patch engine (`update.sh --patch`) with self-re-execution.
- Integrated multi-source blocklist downloader with merge and fallback URL directives.
- Added daily off-peak update scheduler in `/etc/cron.d/smartdns-update`.
- Sourced `LC_ALL=C` locale execution for consistent command output parsing.
- Enhanced signal trap handlers and temporary file cleanup routines using `mktemp`.
- Added GitHub Pages and CodeQL CI workflows.
