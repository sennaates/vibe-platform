import SwiftUI

/// Renders a post caption with tappable #hashtag tokens.
struct CaptionText: View {
    let text: String
    var onHashtagTap: ((String) -> Void)? = nil

    /// Split caption into segments: plain strings and hashtag strings
    private var segments: [(text: String, isTag: Bool)] {
        let pattern = #"(#[\wÀ-ɏЀ-ӿ]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [(text, false)]
        }
        var result: [(String, Bool)] = []
        var lastEnd = text.startIndex
        let nsText = text as NSString
        let fullRange = NSRange(text.startIndex..., in: text)

        for match in regex.matches(in: text, range: fullRange) {
            guard let range = Range(match.range, in: text) else { continue }
            // Plain text before this tag
            if lastEnd < range.lowerBound {
                result.append((String(text[lastEnd..<range.lowerBound]), false))
            }
            // The hashtag
            result.append((String(text[range]), true))
            lastEnd = range.upperBound
        }
        // Trailing plain text
        if lastEnd < text.endIndex {
            result.append((String(text[lastEnd...]), false))
        }
        _ = nsText // suppress unused warning
        return result
    }

    var body: some View {
        // Build a single Text by concatenating segments
        segments.reduce(Text("")) { acc, seg in
            if seg.isTag {
                let tag = String(seg.text.dropFirst()) // remove #
                return acc + Text(seg.text)
                    .foregroundColor(Color.accentColor)
                    .bold()
            } else {
                return acc + Text(seg.text)
                    .foregroundColor(.primary.opacity(0.85))
            }
        }
        .font(.subheadline)
        .onTapGesture { location in
            // Detect which hashtag was tapped via character position
            // SwiftUI Text concatenation doesn't expose tap-per-segment,
            // so we fall back to parsing the whole text on tap.
            handleTap()
        }
    }

    /// On tap, open a sheet or navigate for the first hashtag found.
    /// For per-word taps, callers can use a FlowLayout; here we keep it simple.
    private func handleTap() {
        // Extract all tags and just use a menu-based approach via onHashtagTap callback.
        // We call with the first tag; the parent can present a picker if there are many.
        let pattern = #"#([\wÀ-ɏЀ-ӿ]+)"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range = Range(match.range(at: 1), in: text)
        else { return }
        onHashtagTap?(String(text[range]).lowercased())
    }
}

#Preview {
    CaptionText(
        text: "Bugün çok #mutlu hissettim! #vibe #çizim",
        onHashtagTap: { tag in print("tapped: \(tag)") }
    )
    .padding()
}
