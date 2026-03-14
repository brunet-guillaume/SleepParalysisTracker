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

        Window("form.save", id: "add-episode") {
            EpisodeFormView(store: store)
                .onDisappear { NSApp.setActivationPolicy(.accessory) }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.titleBar)

        MenuBarExtra("Paralysies du sommeil", systemImage: "moon.zzz.fill") {
            MenuBarView(
                openWindow: {
                    NSApp.setActivationPolicy(.regular)
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                },
                openAddForm: {
                    NSApp.setActivationPolicy(.regular)
                    openWindow(id: "add-episode")
                    NSApp.activate(ignoringOtherApps: true)
                }
            )
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
