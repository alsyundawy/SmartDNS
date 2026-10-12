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

### Enhanced
- Maintained 100% ShellCheck compliance across all shell scripts (strict bash expansions, safe subshells, zero lint warnings).
- Standardized array-based package installations in `ui/install-local.sh` to prevent word-splitting bugs (SC2086).
- Guarded `dnsdist` live configuration reloads in `data/update-blocklist.sh` with service active checks.
- Enhanced telemetry UUID migration and validation routines (`lib/telemetry.sh`).

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
