import Foundation

@main
struct TranslationPasteImportContract {
    static func main() throws {
        try timestampedTranslationKeepsSourceTime()
        try untimedEqualLinesInheritOrderOnly()
        try mismatchesArePreviewOnly()
        print("translation paste import contracts passed")
    }

    private static func sourceLines() -> [LyricsEditorLineDraft] {
        [
            LyricsEditorLineDraft(originalText: "one", startTime: 10),
            LyricsEditorLineDraft(originalText: "two", startTime: 20),
            LyricsEditorLineDraft(originalText: "three", startTime: 30)
        ]
    }

    private static func timestampedTranslationKeepsSourceTime() throws {
        let lines = sourceLines()
        let preview = try TranslationPasteImporter.preview(
            content: "[00:10.400]一\n[00:20.400]二\n[00:30.400]三",
            sourceLines: lines,
            sourceIsSynchronized: true,
            target: .translation,
            tolerance: 0.08
        )
        guard preview.canApply, abs((preview.detectedOffset ?? 0) - 0.4) < 0.001 else {
            throw ContractFailure(message: "near timestamp and fixed offset should auto-match")
        }
        let applied = try TranslationPasteImporter.apply(preview, to: lines)
        guard applied.map(\.translationText) == ["一", "二", "三"],
              applied.map(\.startTime) == lines.map(\.startTime),
              applied.map(\.originalText) == lines.map(\.originalText) else {
            throw ContractFailure(message: "translation paste changed source content or timestamps")
        }
    }

    private static func untimedEqualLinesInheritOrderOnly() throws {
        let lines = sourceLines()
        let preview = try TranslationPasteImporter.preview(
            content: "甲\n乙\n丙",
            sourceLines: lines,
            sourceIsSynchronized: true,
            target: .translation
        )
        guard preview.canApply, preview.detectedOffset == nil else {
            throw ContractFailure(message: "equal untimed translation should map sequentially")
        }
        let applied = try TranslationPasteImporter.apply(preview, to: lines)
        guard applied.map(\.translationText) == ["甲", "乙", "丙"] else {
            throw ContractFailure(message: "sequential untimed mapping failed")
        }
    }

    private static func mismatchesArePreviewOnly() throws {
        let lines = sourceLines()
        let preview = try TranslationPasteImporter.preview(
            content: "只有一行",
            sourceLines: lines,
            sourceIsSynchronized: true,
            target: .translation
        )
        guard !preview.canApply,
              preview.missingSourceLineIndices.count == 2,
              preview.ambiguousImportedLineIndices.count == 1 else {
            throw ContractFailure(message: "untimed count mismatch was not surfaced")
        }
        do {
            _ = try TranslationPasteImporter.apply(preview, to: lines)
            throw ContractFailure(message: "count mismatch silently applied")
        } catch TranslationPasteImportError.cannotApply { }
    }
}

private struct ContractFailure: Error {
    let message: String
}
