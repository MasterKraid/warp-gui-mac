# WarpBar - Native macOS Menu Bar GUI for Cloudflare WARP

A lightweight, high-performance, native macOS menu bar app for Cloudflare WARP. Built with Swift, AppKit, and SwiftUI, designed to run exclusively in the macOS menu bar (`LSUIElement = true`) with **zero Dock footprint** and minimal resource usage (~1 MB binary).

---

## Features

- **Exclusive Menu Bar Operation**: Runs quietly in the status bar without a Dock icon or application switcher entry.
- **Dynamic Status Shield**: Dynamic menu bar icon displaying connection status (connected, disconnected, connecting) and network health.
- **One-Click Master Toggle**: Connect or disconnect from WARP instantly with smooth animations.
- **Live Public IP**: Real-time public IP detection with a 1-click copy-to-clipboard button.
- **Complete CLI Toolset Integration**:
  - **Connection Modes**: Seamlessly switch between `WARP`, `DoH (1.1.1.1)`, `WARP+DoH`, `SOCKS5 Proxy`, and `Tunnel Only`.
  - **1.1.1.1 Families**: Enable standard DNS, malware blocking, or adult content filtering with one click.
  - **Split Tunnel (Exclusions)**: View, filter, add, and remove domain or IP routing exclusions.
  - **Live Connection Stats**: View queries, latency, and comprehensive CLI stats.
  - **Diagnostics**: Run network and tunnel health diagnostics on demand.
  - **Daemon Management**: Monitor and restart the background `CloudflareWARP` daemon.
  - **Log Viewer**: Live stream recent daemon logs directly within the popover.
- **Launch at Login**: Easily toggle autostart on system boot.

---

## Build & Install

```bash
cd WarpBar
./bundle.sh
```

This compiles the release binary, packages it into `WarpBar.app`, and installs it into `/Applications/WarpBar.app`.

