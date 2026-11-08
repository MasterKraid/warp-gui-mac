import Cocoa
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var state: WarpState!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = WarpState()

        // 1. Setup Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            updateButtonIcon(connected: state.isConnected, connecting: state.isConnecting)
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // 2. Setup Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MainContentView(state: state))

        // 3. Monitor state changes to update menu bar icon
        state.$isConnected
            .combineLatest(state.$isConnecting)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected, connecting in
                self?.updateButtonIcon(connected: connected, connecting: connecting)
            }
            .store(in: &cancellables)

        // 4. Global click monitor to auto-close popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(event)
            }
        }
    }

    private func updateButtonIcon(connected: Bool, connecting: Bool) {
        guard let button = statusItem.button else { return }

        button.image = createCloudflareMenuIcon(connected: connected, connecting: connecting)
        button.toolTip = connecting ? "WARP: Connecting..." : (connected ? "WARP: Connected (\(state.publicIP))" : "WARP: Disconnected")
    }

    private func createCloudflareMenuIcon(connected: Bool, connecting: Bool) -> NSImage {
        let targetSize = NSSize(width: 20, height: 11)
        let canvasSize = NSSize(width: 22, height: 18)

        // Try loading bundled Cloudflare SVG
        let possiblePaths = [
            Bundle.main.path(forResource: "cloudflare-logo", ofType: "svg"),
            Bundle.main.resourcePath.map { $0 + "/cloudflare-logo.svg" },
            "/Applications/WarpBar.app/Contents/Resources/cloudflare-logo.svg"
        ].compactMap { $0 }

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let original = NSImage(contentsOfFile: path) {
                let img = NSImage(size: canvasSize, flipped: false) { rect in
                    let drawRect = NSRect(
                        x: (canvasSize.width - targetSize.width) / 2,
                        y: (canvasSize.height - targetSize.height) / 2,
                        width: targetSize.width,
                        height: targetSize.height
                    )
                    if !connected && !connecting {
                        original.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 0.4)
                    } else {
                        original.draw(in: drawRect)
                    }
                    return true
                }
                img.isTemplate = true
                return img
            }
        }

        // SF Symbol cloud fallback
        let symbolName = connecting ? "cloud.sun.fill" : (connected ? "cloud.fill" : "cloud")
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "WARP Cloud") {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.isTemplate = true
            return configured
        }

        return NSImage()
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let statusTitle = state.isConnected ? "✓ WARP: Connected" : "○ WARP: Disconnected"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let toggleTitle = state.isConnected ? "Disconnect" : "Connect"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleAction), keyEquivalent: "t"))

        let modeMenu = NSMenu()
        let modes = [("WARP (Full)", "warp"), ("DoH (1.1.1.1)", "doh"), ("WARP + DoH", "warp+doh"), ("SOCKS5 Proxy", "proxy")]
        for (label, modeId) in modes {
            let item = NSMenuItem(title: label, action: #selector(selectModeAction(_:)), keyEquivalent: "")
            item.representedObject = modeId
            if state.currentMode.lowercased().contains(modeId) {
                item.state = .on
            }
            modeMenu.addItem(item)
        }
        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open WarpBar", action: #selector(openPopoverAction), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Restart Daemon", action: #selector(restartDaemonAction), keyEquivalent: "r"))

        let startAtLoginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLoginAction), keyEquivalent: "")
        startAtLoginItem.state = state.launchAtLogin ? .on : .off
        menu.addItem(startAtLoginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WarpBar", action: #selector(quitAction), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleStartAtLoginAction() {
        state.toggleLaunchAtLogin(!state.launchAtLogin)
    }

    @objc private func toggleAction() {
        state.toggle()
    }

    @objc private func selectModeAction(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? String {
            state.switchMode(to: mode)
        }
    }

    @objc private func openPopoverAction() {
        if let button = statusItem.button {
            togglePopover(button)
        }
    }

    @objc private func restartDaemonAction() {
        state.restartDaemon()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
