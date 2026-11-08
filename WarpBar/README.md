# WarpBar (`warp-gui-mac`) ☁️

A lightweight, native macOS menu bar app for Cloudflare WARP. Built with Swift, AppKit, and SwiftUI, designed to run exclusively in the macOS menu bar (`LSUIElement = true`) with **zero Dock footprint** and minimal resource usage (~1 MB binary).

---

## Credits

Built upon the `warp-cli` terminal toolset created by **Ashutosh Tripathi** ([@zero8dotdev](https://github.com/zero8dotdev)) from [zero8dotdev/warp-cli](https://github.com/zero8dotdev/warp-cli).

---

## Features

- **Exclusive Menu Bar Operation**: Runs quietly in the status bar without a Dock icon (`LSUIElement = true`).
- **Cloudflare Cloud Icon**: Dynamic white Cloudflare cloud symbol in the menu bar.
- **Cloudflare Orange Theme**: Polished with `#F6821F` orange accents and SF Pro Rounded typography.
- **One-Click Master Toggle**: Connect or disconnect from WARP instantly.
- **Live Public IP**: Real-time public IP detection with a 1-click copy capsule.
- **Complete CLI Toolset Integration**:
  - **Connection Modes**: `WARP`, `DoH (1.1.1.1)`, `WARP + DoH`, `SOCKS5 Proxy`, `Tunnel Only`.
  - **1.1.1.1 Content Filtering**: Standard, Malware Protection, Families (Adult + Malware).
  - **Split Tunnel (Exclusions)**: View, filter, add, and remove routing exclusions.
  - **Live Connection Stats**: View queries, latency, and comprehensive CLI stats.
  - **Diagnostics & Tools**: Run network diagnostics, view live logs, and restart the background daemon.
- **Right-Click Context Menu**: Toggle connection, switch mode, toggle "Start at Login", and Quit.

---

## Build & Install

```bash
cd WarpBar
./bundle.sh
```

This compiles the release binary, packages it into `WarpBar.app`, and installs it into `/Applications/WarpBar.app`.
