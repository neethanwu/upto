import SwiftUI

@main
struct UpToApp: App {
    @State private var monitor = StatusMonitor()
    @State private var serverMonitor = ServerMonitor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            StatusPopoverView(monitor: monitor, serverMonitor: serverMonitor)
        } label: {
            Image(nsImage: MenuBarIcon.statusImage(
                for: monitor.overallStatus,
                serverCount: serverMonitor.servers.count
            ))
            .renderingMode(.original)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and app switcher
        NSApp.setActivationPolicy(.accessory)
    }
}
