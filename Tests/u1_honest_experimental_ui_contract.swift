import Foundation

@main
struct U1HonestExperimentalUIContract {
    @MainActor
    static func main() {
        var preparationCalls = 0
        var editorOpenCalls = 0

        DirectionDActionRouter.performManualLyricsImport(
            prepare: {
                preparationCalls += 1
                return false
            },
            openEditor: { editorOpenCalls += 1 }
        )
        precondition(preparationCalls == 1, "failed/cancelled preparation must run once")
        precondition(editorOpenCalls == 0, "failed/cancelled preparation must not open the editor")

        DirectionDActionRouter.performManualLyricsImport(
            prepare: {
                preparationCalls += 1
                return true
            },
            openEditor: { editorOpenCalls += 1 }
        )
        precondition(preparationCalls == 2, "successful preparation must run once")
        precondition(editorOpenCalls == 1, "successful preparation must open the existing editor exactly once")
        print("U1 manual import action: cancellation stays closed; success opens editor once")
    }
}
