# warp-gui-mac ☁️

> **A sleek, lightweight, native macOS menu bar wrapper for Cloudflare WARP.**

`warp-gui-mac` replaces the bloated official Cloudflare WARP desktop GUI with a pure native, resource-friendly menu bar experience (`~1 MB`). Styled in signature Cloudflare Orange with modern SF Pro Rounded typography, it runs exclusively in your macOS status bar (`LSUIElement`) with zero Dock clutter.

---

## 👏 Acknowledgements & Credits

This project builds upon the fantastic terminal CLI toolset created by **Ashutosh Tripathi** ([@zero8dotdev](https://github.com/zero8dotdev)) from the original repository:
👉 **[zero8dotdev/warp-cli](https://github.com/zero8dotdev/warp-cli)**

The underlying Rust CLI wrapper (`warp`) and daemon automation scripts were developed by Ashutosh Tripathi. `warp-gui-mac` integrates this toolset into a polished macOS native GUI interface while preserving full command-line capabilities.

---

## ✨ Features

- **Exclusive Menu Bar Operation**: Runs quietly in your status bar with no Dock icon or `⌘-Tab` switcher footprint (`LSUIElement = true`).
- **Cloudflare Cloud Status Icon**: Dynamic status bar icon featuring the white Cloudflare cloud symbol that dims when disconnected and brightens when connected.
- **Cloudflare Orange Theme**: Beautifully crafted with Cloudflare's signature `#F6821F` orange palette and soft translucent glass cards.
- **Master Quick Toggle**: One-click connection switch with instant visual feedback.
- **Live Public IP**: Detects and displays your active public IP address with a 1-click copy capsule.
- **Connection Mode Selector**:
  - `WARP`: Full VPN encryption with Cloudflare DNS
  - `DoH (1.1.1.1)`: Private DNS over HTTPS only
  - `WARP + DoH`: Full VPN tunnel with encrypted DoH
  - `SOCKS5 Proxy`: Local proxy routing on `127.0.0.1`
  - `Tunnel Only`: Direct VPN without DNS proxying
- **1.1.1.1 Content Filtering (Families)**:
  - `Standard`: Unfiltered high-speed DNS
  - `Malware`: Blocks known security threats and malware
  - `Families`: Blocks malware and adult content
- **Split Tunnel Manager**: View, filter, add, and remove domains or IP addresses that bypass the VPN tunnel.
- **Real-Time Performance Stats**: Live query counts, DNS latency, and expandable raw CLI metrics.
- **Diagnostics & Tools**: One-click network diagnostics (`warp diagnose`), daemon status checks, and live log streaming (`cfwarp_service_log.txt`).
- **Right-Click Context Menu**: Right-click the cloud icon for quick actions:
  - Toggle Connection
  - Switch Mode
  - Restart Daemon
  - **Start at Login** (`✓` toggle)
  - **Quit WarpBar** (`⌘Q`)

---

## 🚀 Quick Start

### 1. Prerequisites

Cloudflare WARP's system daemon must be installed on your Mac:
```bash
brew install --cask cloudflare-warp
```
*(You do not need to keep the official GUI app running; the background daemon `CloudflareWARP` is all that's required).*

### 2. Build & Install the Menu Bar App

Clone the repository and run the packaging script:

```bash
git clone https://github.com/MasterKraid/warp-gui-mac.git
cd warp-gui-mac
./WarpBar/bundle.sh
```

This compiles the release binary with Swift, packages it into `WarpBar.app`, and installs it directly to `/Applications/WarpBar.app`.

### 3. Launch

Open the app from `/Applications` or via terminal:
```bash
open /Applications/WarpBar.app
```

The white Cloudflare cloud will appear in your menu bar ready to use!

---

## 💻 Terminal CLI Usage

You can also control everything directly from your terminal using the included `warp` CLI:

```bash
warp status                 # Check connection status & public IP
warp up                     # Connect to WARP
warp down                   # Disconnect
warp toggle                 # Toggle connection on/off
warp mode warp              # Set protocol mode (warp, doh, warp+warp, gateway)
warp exclude list           # List split-tunnel exclusions
warp exclude add site.com   # Add domain or IP to split tunnel
warp exclude remove site.com# Remove from split tunnel
warp stats                  # Show connection quality & query stats
warp daemon status          # Check launchd background daemon
warp logs                   # Stream daemon service logs
warp diagnose               # Run full network health diagnostics
```

---

## 🛠️ Architecture

- **GUI App (`WarpBar`)**: Native Swift 6 + SwiftUI + AppKit menu bar popover (`WarpBar/Sources/WarpBar`).
- **CLI Engine (`warp`)**: Rust CLI wrapper communicating with the Cloudflare IPC daemon (`src/`).
- **Daemon (`CloudflareWARP`)**: Background root launchd daemon (`com.cloudflare.1dot1dot1dot1.macos.warp.daemon`).

---

## 📄 License & Disclaimer

- **License**: MIT
- **Attribution**: Based on [`warp-cli`](https://github.com/zero8dotdev/warp-cli) by [Ashutosh Tripathi](https://github.com/zero8dotdev).
- **Disclaimer**: Not affiliated with, endorsed by, or sponsored by Cloudflare, Inc. Cloudflare and WARP are registered trademarks of Cloudflare, Inc.
