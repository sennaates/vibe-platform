import SwiftUI

/// Renders a post caption with tappable #hashtag tokens.
/// Tapping anywhere in the caption fires onHashtagTap with the first tag found.
struct CaptionText: View {
    let text: String
    var onHashtagTap: ((String) -> Void)? = nil

    // MARK: - Segmentlere ayır

    private var segments: [(text: String, isTag: Bool)] {
        let pattern = #"(#[\wÀ-ɏЀ-ӿ]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [(text, false)]
        }
        var result: [(String, Bool)] = []
        var lastEnd = text.startIndex
        let fullRange = NSRange(text.startIndex..., in: text)

        for match in regex.matches(in: text, range: fullRange) {
            guard let range = Range(match.range, in: text) else { continue }
            if lastEnd < range.lowerBound {
                result.append((String(text[lastEnd..<range.lowerBound]), false))
            }
            result.append((String(text[range]), true))
            lastEnd = range.upperBound
        }
        if lastEnd < text.endIndex {
            result.append((String(text[lastEnd...]), false))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        segments.reduce(Text("")) { acc, seg in
            if seg.isTag {
                return acc + Text(seg.text)
                    .foregroundColor(Color.accentColor)
                    .bold()
            } else {
                return acc + Text(seg.text)
                    .foregroundColor(.primary.opacity(0.85))
            }
        }
        .font(.subheadline)
        .onTapGesture {
            handleTap()
        }
    }

    // MARK: - İlk hashtag'i çek ve callback'e ilet

    private func handleTap() {
        guard let onHashtagTap else { return }
        let pattern = #"#([\wÀ-ɏЀ-ӿ]+)"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
            ),
            let range = Range(match.range(at: 1), in: text)
        else { return }
        onHashtagTap(String(text[range]).lowercased())
    }
}

#Preview {
    CaptionText(
        text: "Bugün çok #mutlu hissettim! #vibe #çizim",
        onHashtagTap: { tag in print("tapped: \(tag)") }
    )
    .padding()
}
