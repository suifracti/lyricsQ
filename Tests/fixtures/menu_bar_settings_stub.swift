import Combine

// Route-only host: no UserDefaults access or persistence is needed.
public final class AppSettingsStore: ObservableObject {
    public static let shared = AppSettingsStore()
    @Published public var menuBarLyricsEnabled = true
}
