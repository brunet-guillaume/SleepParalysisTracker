import SwiftUI
import ServiceManagement

@main
struct SleepParalysisTrackerApp: App {
    @State private var store = EpisodeStore()
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Sleep Paralysis Tracker", id: "main") {
            ContentView()
                .environment(store)
                .onAppear { NSApp.setActivationPolicy(.regular) }
                .onDisappear { NSApp.setActivationPolicy(.accessory) }
        }
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)

        MenuBarExtra("Paralysies du sommeil", systemImage: "moon.zzz.fill") {
            MenuBarView(openWindow: { openWindow(id: "main") })
                .environment(store)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
}
