import AppKit
import SwiftUI
@MainActor enum ProbeEvidence { static var appearances = 0 }
@main struct SettingsRouteContract: App {
 var body: some Scene {
  Window("Isolated Reliability Settings", id: "probe") { ProbeView() }
  Settings {
   Text("Isolated Settings Contract").padding()
    .onAppear { ProbeEvidence.appearances += 1 }
  }.commands {
   CommandGroup(replacing: .appSettings) { SettingsLink { Text("设置…") } }
  }
 }
}
struct ProbeView: View {
 @Environment(\.openSettings) private var openSettings
 var body: some View {
  Text("Temporary reliability host").padding().task {
   try? await Task.sleep(for: .milliseconds(400))
   // Native handler is bound here, matching MainLyricsWindowView's environment boundary.
   MenuBarLyricsController.shared.setOpenSettingsHandler { [openSettings] in openSettings() }
   MenuBarLyricsController.shared.openSettings()
   try? await Task.sleep(for: .milliseconds(700))
   precondition(ProbeEvidence.appearances > 0, "MenuBar Settings must open native Settings scene")
   let settingsWindow = NSApp.windows.first { $0.isVisible && $0.title != "Isolated Reliability Settings" }
   precondition(settingsWindow != nil)
   MenuBarLyricsController.shared.openSettings()
   try? await Task.sleep(for: .milliseconds(300))
   precondition(settingsWindow?.isVisible == true, "Repeated open must keep Settings visible")
   NSApp.windows.first { $0.title == "Isolated Reliability Settings" }?.close()
   settingsWindow?.close()
   MenuBarLyricsController.shared.openSettings()
   try? await Task.sleep(for: .milliseconds(600))
   precondition(NSApp.windows.contains { $0.isVisible && $0.title != "Isolated Reliability Settings" }, "Settings must reopen after main window closes")
   print("PASS native Settings first open, repeated open, and reopen after main closes")
   NSApp.terminate(nil)
  }
 }
}
