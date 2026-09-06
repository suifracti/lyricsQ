import AppKit

enum TrackMetadataCopy {
    @discardableResult
    static func copy(_ text: String, to pasteboard: NSPasteboard = .general) -> Bool {
        guard !text.isEmpty else { return false }
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }
}
