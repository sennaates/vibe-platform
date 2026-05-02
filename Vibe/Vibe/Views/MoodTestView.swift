import SwiftUI

// MARK: - Model

struct MoodQuestion {
    let id: Int
    let prompt: String
    let lowLabel: String
    let highLabel: String
    let lowEmoji: String
    let highEmoji: String
    let dimension: Dimension

    enum Dimension {
        case arousal
        case valence
        case stress
    }
}

private let questions: [MoodQuestion] = [
    MoodQuestion(id: 0, prompt: "Şu an enerjini nasıl hissediyorsun?",
                 lowLabel: "Bitik", highLabel: "Enerjik",
                 lowEmoji: "😴", highEmoji: "⚡", dimension: .arousal),
    MoodQuestion(id: 1, prompt: "Genel duygu durumun nasıl?",
                 lowLabel: "Çok kötü", highLabel: "Çok iyi",
                 lowEmoji: "😞", highEmoji: "😄", dimension: .valence),
    MoodQuestion(id: 2, prompt: "Ne kadar gergin veya stresli hissediyorsun?",
                 lowLabel: "Hiç değil", highLabel: "Çok fazla",
                 lowEmoji: "🧘", highEmoji: "😤", dimension: .stress),
    MoodQuestion(id: 3, prompt: "Zihnin ne kadar aktif ve meşgul?",
                 lowLabel: "Boş", highLabel: "Canlı",
                 lowEmoji: "🌫️", highEmoji: "🔥", dimension: .arousal),
    MoodQuestion(id: 4, prompt: "Bedenini nasıl hissediyorsun?",
                 lowLabel: "Ağır", highLabel: "Hafif",
                 lowEmoji: "🪨", highEmoji: "🍃", dimension: .valence),
]

// MARK: - View

struct MoodTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var biometricService: BiometricService
    var onApply: (() -> Void)? = nil

    @State private var currentIndex = 0
    @State private var answers: [Int: Int] = [:]
    @State private var result: EmotionState? = nil
    @State private var showingResult = false

    var body: some View {
        NavigationStack {
            Group {
                if showingResult, let emotion = result {
                    resultView(emotion: emotion)
                } else {
                    questionView
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Duygu Testi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: currentIndex)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: showingResult)
        }
    }

    // MARK: - Soru

    private var questionView: some View {
        VStack(spacing: 0) {
            // İlerleme
            VStack(spacing: 8) {
                progressBar
                Text("Soru \(currentIndex + 1) / \(questions.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColor.inkMuted)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)

            Spacer()

            let q = questions[currentIndex]

            VStack(spacing: AppSpacing.xl) {
                // Soru metni
                Text(q.prompt)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(AppColor.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .lineSpacing(4)
                    .id(q.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                // 5 nokta seçeneği
                optionRow(for: q)
                    .id("opts_\(q.id)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                // Uç etiketler
                HStack {
                    VStack(spacing: 3) {
                        Text(q.lowEmoji).font(.system(size: 22))
                        Text(q.lowLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColor.inkMuted)
                    }
                    Spacer()
                    VStack(spacing: 3) {
                        Text(q.highEmoji).font(.system(size: 22))
                        Text(q.highLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColor.inkMuted)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
            }

            Spacer()

            // İleri butonu
            let isAnswered = answers[questions[currentIndex].id] != nil
            PrimaryButton(
                title: currentIndex == questions.count - 1 ? "Sonucu Gör" : "İleri",
                icon: "arrow.right",
                color: isAnswered ? AppColor.accent : AppColor.inkMuted.opacity(0.5)
            ) {
                advance()
            }
            .disabled(!isAnswered)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
    }

    private func optionRow(for question: MoodQuestion) -> some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                let selected = answers[question.id] == value
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        answers[question.id] = value
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(selected ? AppColor.accent : AppColor.surface)
                            .frame(width: 54, height: 54)
                            .overlay(
                                Circle().strokeBorder(
                                    selected ? AppColor.accent : AppColor.divider,
                                    lineWidth: selected ? 0 : 1
                                )
                            )
                        Text("\(value)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selected ? .white : AppColor.ink)
                    }
                    .scaleEffect(selected ? 1.10 : 1.0)
                    .shadow(color: selected ? AppColor.accent.opacity(0.30) : .clear, radius: 8, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColor.surfaceMuted).frame(height: 4)
                Capsule()
                    .fill(AppColor.accent)
                    .frame(
                        width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count),
                        height: 4
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Sonuç

    private func resultView(emotion: EmotionState) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Sonuç kartı
                VStack(spacing: AppSpacing.md) {
                    Text(emotion.emoji)
                        .font(.system(size: 80))
                        .transition(.scale.combined(with: .opacity))

                    Text(emotion.displayName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(emotion.color)

                    Text(emotion.resultDescription)
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                        .lineSpacing(3)
                }
                .padding(.vertical, AppSpacing.xl)
                .frame(maxWidth: .infinity)
                .background(emotion.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .strokeBorder(emotion.color.opacity(0.20), lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                // Skor detayı
                scoreDetailView

                Spacer(minLength: 20)

                // Aksiyonlar
                VStack(spacing: 10) {
                    PrimaryButton(
                        title: "Uygula ve Çizmeye Başla",
                        icon: "arrow.right",
                        color: emotion.color
                    ) {
                        biometricService.enableMockMode()
                        biometricService.setMockBPM(emotion.testResultBPM)
                        dismiss()
                        onApply?()
                    }

                    SecondaryButton(title: "Testi Tekrarla", icon: "arrow.counterclockwise") {
                        answers = [:]
                        currentIndex = 0
                        showingResult = false
                        result = nil
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
            }
        }
    }

    private var scoreDetailView: some View {
        let (arousal, valence) = computeScores()
        return HStack(spacing: 12) {
            ScoreChip(label: "Enerji", value: arousal, color: .orange)
            ScoreChip(label: "Pozitiflik", value: valence, color: .blue)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Hesaplama

    private func computeScores() -> (arousal: Double, valence: Double) {
        let arousalRaw = [Double(answers[0] ?? 3), Double(answers[3] ?? 3)]
        let valenceRaw = [Double(answers[1] ?? 3), Double(answers[4] ?? 3),
                          6.0 - Double(answers[2] ?? 3)]
        return (arousalRaw.reduce(0, +) / Double(arousalRaw.count),
                valenceRaw.reduce(0, +) / Double(valenceRaw.count))
    }

    private func computeEmotion() -> EmotionState {
        let (arousal, valence) = computeScores()
        switch (arousal > 3.0, valence > 3.0) {
        case (true, true):   return .energetic
        case (true, false):  return .stressed
        case (false, true):  return .calm
        case (false, false): return .stressed
        }
    }

    private func advance() {
        if currentIndex < questions.count - 1 {
            withAnimation { currentIndex += 1 }
        } else {
            let emotion = computeEmotion()
            result = emotion
            HapticManager.notification(.success)
            withAnimation { showingResult = true }
        }
    }
}

// MARK: - Yardımcı

private struct ScoreChip: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - EmotionState ek

private extension EmotionState {
    var resultDescription: String {
        switch self {
        case .calm:
            return "Enerji seviyenin düşük ve duygu durumun olumlu. Sakin bir yaratıcılık için harika bir an."
        case .energetic:
            return "Hem enerji seviyenin hem duygu durumunun yüksek. Dinamik çizimler için ideal."
        case .stressed:
            return "Gerginlik veya yorgunluk var. Çizmek bu duyguları dışa vurman için iyi bir yol olabilir."
        case .unknown:
            return ""
        }
    }

    var testResultBPM: Int {
        switch self {
        case .calm:      return 62
        case .energetic: return 85
        case .stressed:  return 112
        case .unknown:   return 72
        }
    }
}
