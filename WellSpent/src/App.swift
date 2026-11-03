import SwiftUI
import AppKit

@main
struct WellSpentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = TodoStore()

    var body: some Scene {
        Window("WellSpent", id: "main") {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(Theme.colorScheme(for: store.appearanceMode))
                .frame(minWidth: WindowGeometry.minimumContentSize(compact: store.compactMode).width,
                       minHeight: WindowGeometry.minimumContentSize(compact: store.compactMode).height)
                .onAppear { appDelegate.configureWindow(store: store) }
                .onChange(of: store.compactMode) { _ in appDelegate.updateWindow() }
                .onChange(of: store.windowAlpha) { _ in appDelegate.updateWindow() }
                .onChange(of: store.appearanceMode) { _ in appDelegate.updateWindow() }
                .onChange(of: store.alwaysOnTop) { _ in appDelegate.updateWindow() }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                    store.commitEditing()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private weak var mainWindow: NSWindow?
    private weak var store: TodoStore?
    private var restoringFrame = false
    private var displayedCompactMode: Bool?
    private var discardOnExit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil)
    }

    func configureWindow(store: TodoStore) {
        self.store = store
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.mainWindow != nil {
                self.updateWindow()
                return
            }
            guard let window = NSApp.mainWindow ?? NSApp.windows.first else { return }
            self.mainWindow = window
            window.delegate = self
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.isMovableByWindowBackground = true
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            self.updateWindow()
        }
    }

    func updateWindow() {
        guard let window = mainWindow, let store else { return }
        window.alphaValue = store.compactMode ? 1 : CGFloat(store.windowAlpha)
        window.appearance = Theme.nsAppearance(for: store.appearanceMode)
        window.level = store.alwaysOnTop ? .floating : .normal
        window.collectionBehavior = store.alwaysOnTop ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
        if displayedCompactMode != store.compactMode {
            restoreFrame(compact: store.compactMode)
        }
    }

    private func restoreFrame(compact: Bool) {
        guard let window = mainWindow else { return }
        let previousFrame = window.frame
        let switchingMode = displayedCompactMode != nil
        restoringFrame = true
        displayedCompactMode = compact
        window.contentMinSize = WindowGeometry.minimumContentSize(compact: compact)
        let key = Theme.windowFrameKey + (compact ? ".Compact" : "")
        let proposed: NSRect
        if let saved = UserDefaults.standard.string(forKey: key),
           WindowGeometry.isValid(NSRectFromString(saved)) {
            proposed = NSRectFromString(saved)
        } else {
            var frame = window.frameRect(forContentRect: NSRect(origin: .zero,
                size: WindowGeometry.defaultContentSize(compact: compact)))
            if switchingMode {
                frame.origin = NSPoint(x: previousFrame.minX, y: previousFrame.maxY - frame.height)
            } else if let screen = visibleScreens.first {
                frame.origin = NSPoint(x: screen.maxX - frame.width - 40, y: screen.maxY - frame.height - 40)
            }
            proposed = frame
        }
        window.setFrame(fittedFrame(proposed), display: true)
        restoringFrame = false
        saveFrame()
    }

    private func fittedFrame(_ proposed: NSRect) -> NSRect {
        guard let window = mainWindow, let store else { return proposed }
        let minimum = window.frameRect(forContentRect: NSRect(origin: .zero,
            size: WindowGeometry.minimumContentSize(compact: store.compactMode))).size
        return WindowGeometry.fitted(proposed, screens: visibleScreens, minimumSize: minimum)
    }

    private var visibleScreens: [NSRect] { NSScreen.screens.map(\.visibleFrame) }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }

    private func saveFrame() {
        guard !restoringFrame, let window = mainWindow, let store,
              displayedCompactMode == store.compactMode, WindowGeometry.isValid(window.frame) else { return }
        let key = Theme.windowFrameKey + (store.compactMode ? ".Compact" : "")
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: key)
    }

    @objc private func screensChanged() {
        guard let window = mainWindow else { return }
        window.setFrame(fittedFrame(window.frame), display: true)
        saveFrame()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool { prepareToExit() }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        prepareToExit() ? .terminateNow : .terminateCancel
    }

    private func prepareToExit() -> Bool {
        guard !discardOnExit, let store else { return true }
        mainWindow?.makeFirstResponder(nil)
        store.commitEditing()
        saveFrame()
        if store.flush() { return true }

        while true {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "还有未保存的更改"
            alert.informativeText = "保存没有成功。您可以重试，或取消退出以保留窗口中的内容。"
            alert.addButton(withTitle: "重试保存")
            alert.addButton(withTitle: "取消退出")
            alert.addButton(withTitle: "放弃更改并退出")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                if store.flush() { return true }
            case .alertThirdButtonReturn:
                discardOnExit = true
                return true
            default:
                return false
            }
        }
    }
}
