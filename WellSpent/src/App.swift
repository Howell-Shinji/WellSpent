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
                .frame(minWidth: 320, minHeight: 460)
                .onAppear { appDelegate.configureWindow(store: store) }
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
            window.minSize = NSSize(width: 320, height: 460)
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            self.updateWindow()

            self.restoringFrame = true
            if let saved = UserDefaults.standard.string(forKey: Theme.windowFrameKey),
               WindowGeometry.isValid(NSRectFromString(saved)) {
                window.setFrame(WindowGeometry.fitted(NSRectFromString(saved), screens: self.visibleScreens),
                                display: true)
            } else {
                window.setContentSize(NSSize(width: 380, height: 520))
                if let screen = self.visibleScreens.first {
                    var frame = window.frame
                    frame.origin = NSPoint(x: screen.maxX - frame.width - 40,
                                           y: screen.maxY - frame.height - 40)
                    window.setFrame(WindowGeometry.fitted(frame, screens: self.visibleScreens), display: true)
                }
            }
            self.restoringFrame = false
            self.saveFrame()
        }
    }

    func updateWindow() {
        guard let window = mainWindow, let store else { return }
        window.alphaValue = CGFloat(store.windowAlpha)
        window.appearance = Theme.nsAppearance(for: store.appearanceMode)
        window.level = store.alwaysOnTop ? .floating : .normal
        window.collectionBehavior = store.alwaysOnTop ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
    }

    private var visibleScreens: [NSRect] { NSScreen.screens.map(\.visibleFrame) }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }

    private func saveFrame() {
        guard !restoringFrame, let window = mainWindow, WindowGeometry.isValid(window.frame) else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: Theme.windowFrameKey)
    }

    @objc private func screensChanged() {
        guard let window = mainWindow else { return }
        window.setFrame(WindowGeometry.fitted(window.frame, screens: visibleScreens), display: true)
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
