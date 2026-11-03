import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var floatingWindow: NSWindow?
    private var floatingHostingController: NSViewController?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: TranslationPopoverView()
                .environmentObject(appState)
        )
        appState.onRequestShowPopover = { [weak self] in
            self?.showFloatingWindow()
        }
        appState.onPinChanged = { [weak self] in
            guard let self else { return }
            (self.floatingWindow as? NSPanel)?.hidesOnDeactivate = !self.appState.isPinned
            if self.appState.isPinned {
                self.popover.performClose(nil)
                self.showFloatingWindow()
            }
        }
    }

    func install() {
        statusItem.menu = nil

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Flash Translate")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc
    func togglePopover() {
        guard let button = statusItem.button else { return }

        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = buildMenu()
            button.performClick(nil)
            statusItem.menu = nil
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        if appState.isPinned {
            showFloatingWindow()
            return
        }
        guard let button = statusItem.button else { return }

        NSApp.activate(ignoringOtherApps: true)

        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showFloatingWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // 如果窗口已经显示，不重复打开
        if let existingWindow = floatingWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        // 计算新位置
        guard let screen = NSScreen.main else { return }
        let mouseLocation = NSEvent.mouseLocation
        let windowSize = NSSize(width: 360, height: 480)
        let screenFrame = screen.visibleFrame

        // 计算初始位置（鼠标右下方）
        var windowOrigin = NSPoint(
            x: mouseLocation.x + 10,
            y: mouseLocation.y - windowSize.height - 10
        )

        // 检查右边界
        if windowOrigin.x + windowSize.width > screenFrame.maxX {
            windowOrigin.x = screenFrame.maxX - windowSize.width - 10
        }

        // 检查左边界
        if windowOrigin.x < screenFrame.minX {
            windowOrigin.x = screenFrame.minX + 10
        }

        // 检查下边界
        if windowOrigin.y < screenFrame.minY {
            windowOrigin.y = screenFrame.minY + 10
        }

        // 检查上边界
        if windowOrigin.y + windowSize.height > screenFrame.maxY {
            windowOrigin.y = screenFrame.maxY - windowSize.height - 10
        }

        // 如果窗口已存在但已关闭，先清理
        if floatingWindow != nil {
            floatingWindow = nil
            floatingHostingController = nil
        }

        // 创建新窗口
        let hostingController = NSHostingController(
            rootView: TranslationPopoverView()
                .environmentObject(appState)
        )
        floatingHostingController = hostingController

        let window = NSPanel(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Flash Translate"
        window.isFloatingPanel = true
        window.hidesOnDeactivate = !appState.isPinned
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.contentViewController = hostingController
        window.alphaValue = 0
        floatingWindow = window

        // 显示窗口并淡入
        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1.0
        }
    }

    func closeFloatingWindow() {
        floatingWindow?.orderOut(nil)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "打开设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let permissionItem = NSMenuItem(title: "重新授权权限", action: #selector(reopenPermissions), keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Flash Translate", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    @objc
    private func openSettings() {
        appState.openSettings()
    }

    @objc
    private func reopenPermissions() {
        appState.reopenPermissionGuidance()
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }
}
