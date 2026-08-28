import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

@main
struct TTMLParserContract {
    static func assertRule(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            print("FAIL: \(message)")
            exit(1)
        }
    }

    static func main() {
        let identity = TrackIdentity(title: "Test Song", artist: "Artist", album: "Album", duration: 120)

        // 1. Contract: outside-span whitespace
        let whitespaceTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml" xmlns:ttm="http://www.w3.org/ns/ttml#metadata">
          <body>
            <div>
              <p begin="00:01.000" end="00:04.000">
                <span begin="00:01.000" end="00:02.000">Hello</span> <span begin="00:02.000" end="00:04.000">World</span>
              </p>
            </div>
          </body>
        </tt>
        """
        guard let wsDoc = TTMLParser.parse(whitespaceTTML, identity: identity, source: .amll),
              let wsLine = wsDoc.lines.first else {
            print("FAIL: whitespaceTTML parse failed")
            exit(1)
        }
        assertRule(wsLine.originalText == "Hello World", "Expected 'Hello World', got '\(wsLine.originalText)'")
        assertRule(wsLine.timedSpans?.count == 2, "Expected 2 timed spans, got \(wsLine.timedSpans?.count ?? 0)")
        let span0 = wsLine.timedSpans![0]
        let span1 = wsLine.timedSpans![1]
        assertRule(span0.text == "Hello" && span0.utf16Start == 0 && span0.utf16Length == 5, "Span 0 range mismatch")
        assertRule(span1.text == "World" && span1.utf16Start == 6 && span1.utf16Length == 5, "Span 1 range mismatch")
        assertRule(wsLine.resolvedGraphemeSpans() != nil, "Resolved grapheme spans must not be nil")
        let resolved = wsLine.resolvedGraphemeSpans()!
        assertRule(wsLine.originalText[resolved[0].range] == "Hello", "Resolved span 0 mismatch")
        assertRule(wsLine.originalText[resolved[1].range] == "World", "Resolved span 1 mismatch")

        // 2. Contract: untimed primary span (No fake timestamps)
        let untimedTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml">
          <body>
            <div>
              <p begin="00:01.000" end="00:05.000">
                <span>Hello</span> World
              </p>
            </div>
          </body>
        </tt>
        """
        guard let untimedDoc = TTMLParser.parse(untimedTTML, identity: identity, source: .amll),
              let untimedLine = untimedDoc.lines.first else {
            print("FAIL: untimedTTML parse failed")
            exit(1)
        }
        assertRule(untimedLine.originalText == "Hello World", "Untimed text mismatch, got '\(untimedLine.originalText)'")
        assertRule(untimedLine.timedSpans == nil, "Untimed spans must not fabricate timestamps: expected nil")

        // 3. Contract: itunes:timing="Line"
        let lineModeTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml" itunes:timing="Line">
          <body>
            <div>
              <p begin="00:01.000" end="00:05.000">
                <span begin="00:01.000" end="00:02.000">Hello</span> <span begin="00:02.000" end="00:05.000">World</span>
              </p>
            </div>
          </body>
        </tt>
        """
        guard let lineModeDoc = TTMLParser.parse(lineModeTTML, identity: identity, source: .amll),
              let lineModeLine = lineModeDoc.lines.first else {
            print("FAIL: lineModeTTML parse failed")
            exit(1)
        }
        assertRule(lineModeLine.originalText == "Hello World", "Line mode text mismatch")
        assertRule(lineModeLine.timedSpans == nil, "Line mode must force timedSpans = nil")

        // 4. Contract: itunes:timing="Word"
        let wordModeTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml" itunes:timing="Word">
          <body>
            <div>
              <p begin="00:01.000" end="00:05.000">
                <span begin="00:01.000" end="00:02.000">Hello</span>
              </p>
            </div>
          </body>
        </tt>
        """
        guard let wordModeDoc = TTMLParser.parse(wordModeTTML, identity: identity, source: .amll),
              let wordModeLine = wordModeDoc.lines.first else {
            print("FAIL: wordModeTTML parse failed")
            exit(1)
        }
        assertRule(wordModeLine.originalText == "Hello", "Word mode text mismatch")
        assertRule(wordModeLine.timedSpans?.count == 1, "Word mode must retain valid timed spans")

        // 5. Contract: mixed timed span + direct text
        let mixedTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml">
          <body>
            <div>
              <p begin="00:01.000" end="00:05.000">
                <span begin="00:01.000" end="00:02.000">One</span>, two, <span begin="00:03.000" end="00:04.000">three</span>
              </p>
            </div>
          </body>
        </tt>
        """
        guard let mixedDoc = TTMLParser.parse(mixedTTML, identity: identity, source: .amll),
              let mixedLine = mixedDoc.lines.first else {
            print("FAIL: mixedTTML parse failed")
            exit(1)
        }
        assertRule(mixedLine.originalText == "One, two, three", "Mixed text mismatch, got '\(mixedLine.originalText)'")
        assertRule(mixedLine.timedSpans?.count == 2, "Expected 2 timed spans in mixed line")
        assertRule(mixedLine.timedSpans![0].text == "One" && mixedLine.timedSpans![0].utf16Start == 0, "Span 0 offset mismatch")
        assertRule(mixedLine.timedSpans![1].text == "three" && mixedLine.timedSpans![1].utf16Start == 10, "Span 1 offset mismatch")

        // 6. Contract: nested x-bg + x-translation + x-roman filtering + duet agents
        let fullFixtureTTML = """
        <?xml version="1.0" encoding="utf-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml" xmlns:ttm="http://www.w3.org/ns/ttml#metadata" xmlns:itunes="http://music.apple.com/metadata">
          <head>
            <metadata>
              <ttm:title>Sample Duet</ttm:title>
              <ttm:agent xml:id="v1" type="person" />
              <ttm:agent xml:id="v2" type="person" />
            </metadata>
          </head>
          <body>
            <div>
              <p begin="00:01.000" end="00:04.000" ttm:agent="v1" itunes:key="L1">
                <span begin="00:01.000" end="00:02.000">思って</span>
                <span begin="00:02.000" end="00:04.000">いる</span>
                <span ttm:role="x-translation" xml:lang="zh-CN">思考着</span>
                <span ttm:role="x-roman">o mo tte i ru</span>
              </p>
              <p begin="00:05.000" end="00:08.500" ttm:agent="v2" itunes:key="L2">
                <span begin="00:05.000" end="00:06.000">Hello</span> <span begin="00:06.000" end="00:08.500">World</span>
                <span ttm:role="x-bg">
                  <span begin="00:07.000" end="00:07.500"> (Harmonized </span>
                  <span begin="00:07.500" end="00:08.500">echo)</span>
                </span>
                <span ttm:role="x-translation" xml:lang="zh-CN">你好世界</span>
                <span ttm:role="x-roman">Hello World</span>
              </p>
              <p begin="00:13.000" end="00:15.000" ttm:role="x-bg">
                <span begin="00:13.000" end="00:15.000">Background chorus line</span>
              </p>
            </div>
          </body>
        </tt>
        """
        guard let fullDoc = TTMLParser.parse(fullFixtureTTML, identity: identity, source: .amll) else {
            print("FAIL: fullFixtureTTML parse failed")
            exit(1)
        }
        assertRule(fullDoc.lines.count == 2, "Expected 2 primary lines (background chorus ignored), got \(fullDoc.lines.count)")
        assertRule(fullDoc.lines[0].performerID == "v1", "Line 0 performer should be v1")
        assertRule(fullDoc.lines[0].originalText == "思っている", "Line 0 text mismatch")
        assertRule(fullDoc.lines[0].timedSpans?.count == 2, "Line 0 span count mismatch")
        assertRule(fullDoc.lines[1].performerID == "v2", "Line 1 performer should be v2")
        assertRule(fullDoc.lines[1].originalText == "Hello World", "Line 1 text mismatch")
        assertRule(fullDoc.lines[1].timedSpans?.count == 2, "Line 1 span count mismatch")

        print("PASS: TTML parser contract verified (canonical stream, untimed spans, itunes timing, nested x-bg, fail-closed mapping)")
    }
}
