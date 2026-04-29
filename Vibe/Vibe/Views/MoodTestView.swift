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
        case arousal    // yüksek = aktif/enerjik
        case valence    // yüksek = iyi/pozitif
        case stress     // yüksek = stresli (valence'ı ters etkiler)
    }
}

// 5 soru — Russell Circumplex + VAMS'tan uyarlanmış
private let questions: [MoodQuestion] = [
    MoodQuestion(
        id: 0,
        prompt: "Şu an enerjini nasıl hissediyorsun?",
        lowLabel: "Bitik", highLabel: "Enerjik",
        lowEmoji: "😴", highEmoji: "⚡",
        dimension: .arousal
    ),
    MoodQuestion(
        id: 1,
        prompt: "Genel duygu durumun nasıl?",
        lowLabel: "Çok kötü", highLabel: "Çok iyi",
        lowEmoji: "😞", highEmoji: "😄",
        dimension: .valence
    ),
    MoodQuestion(
        id: 2,
        prompt: "Ne kadar gergin veya stresli hissediyorsun?",
        lowLabel: "Hiç değil", highLabel: "Çok fazla",
        lowEmoji: "🧘", highEmoji: "😤",
        dimension: .stress
    ),
    MoodQuestion(
        id: 3,
        prompt: "Zihnin ne kadar aktif ve meşgul?",
        lowLabel: "Boş/Uyuşuk", highLabel: "Canlı/Keskin",
        lowEmoji: "🌫️", highEmoji: "🔥",
        dimension: .arousal
    ),
    MoodQuestion(
        id: 4,
        prompt: "Bedenini nasıl hissediyorsun?",
        lowLabel: "Ağır/Yorgun", highLabel: "Hafif/Rahat",
        lowEmoji: "🪨", highEmoji: "🍃",
        dimension: .valence
    ),
]

// MARK: - View

struct MoodTestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var biometricService: BiometricService
    var onApply: (() -> Void)? = nil

    @State private var currentIndex = 0
    @State private var answers: [Int: Int] = [:]  // questionId → 1...5
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
            .navigationTitle("Duygu Testi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: currentIndex)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: showingResult)
        }
    }

    // MARK: - Soru Ekranı

    private var questionView: some View {
        VStack(spacing: 0) {
            // İlerleme çubuğu
            progressBar
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            let q = questions[currentIndex]

            VStack(spacing: 32) {
                // Soru numarası + metin
                VStack(spacing: 12) {
                    Text("\(currentIndex + 1) / \(questions.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    Text(q.prompt)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(q.id)
                }

                // 5 seçenek
                optionRow(for: q)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id("options_\(q.id)")

                // Uç etiketler
                HStack {
                    VStack(spacing: 2) {
                        Text(q.lowEmoji).font(.title3)
                        Text(q.lowLabel).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(q.highEmoji).font(.title3)
                        Text(q.highLabel).font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // İleri / Bitir butonu
            Button(action: advance) {
                Text(currentIndex == questions.count - 1 ? "Sonucu Gör" : "İleri")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(answers[questions[currentIndex].id] != nil ? Color.blue : Color.gray.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(answers[questions[currentIndex].id] == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
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
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(selected ? Color.blue : Color(UIColor.secondarySystemBackground))
                                .frame(width: 52, height: 52)
                            Text("\(value)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(selected ? .white : .primary)
                        }
                        .scaleEffect(selected ? 1.1 : 1.0)
                        .shadow(color: selected ? .blue.opacity(0.35) : .clear, radius: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 6)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(questions.count), height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentIndex)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Sonuç Ekranı

    private func resultView(emotion: EmotionState) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text(emotion.emoji)
                    .font(.system(size: 90))
                    .transition(.scale.combined(with: .opacity))

                Text(emotion.displayName)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(emotion.color)

                Text(emotion.resultDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(emotion.color.opacity(0.1))
            )
            .padding(.horizontal, 24)

            // Skor detayı
            scoreDetailView

            Spacer()

            VStack(spacing: 12) {
                Button {
                    biometricService.enableMockMode()
                    biometricService.setMockBPM(emotion.testResultBPM)
                    dismiss()
                    onApply?()
                } label: {
                    Text("Uygula ve Çizmeye Başla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(emotion.color)
                        .cornerRadius(14)
                }

                Button {
                    // Testi yeniden başlat
                    answers = [:]
                    currentIndex = 0
                    showingResult = false
                    result = nil
                } label: {
                    Text("Testi Tekrarla")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var scoreDetailView: some View {
        let (arousal, valence) = computeScores()
        return HStack(spacing: 16) {
            ScoreChip(
                label: "Enerji / Aktivasyon",
                value: arousal,
                color: .orange
            )
            ScoreChip(
                label: "Duygu / Valence",
                value: valence,
                color: .blue
            )
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Hesaplama (Russell Circumplex)

    private func computeScores() -> (arousal: Double, valence: Double) {
        // Arousal: Q0 (enerji) + Q3 (zihin aktivasyonu) — yüksek = aktif
        let arousalRaw = [
            Double(answers[0] ?? 3),
            Double(answers[3] ?? 3)
        ]

        // Valence: Q1 (genel duygu) + Q4 (beden) — yüksek = pozitif
        // Q2 (stres) ters: yüksek stres = düşük valence
        let valenceRaw = [
            Double(answers[1] ?? 3),
            Double(answers[4] ?? 3),
            6.0 - Double(answers[2] ?? 3)
        ]

        let arousal = arousalRaw.reduce(0, +) / Double(arousalRaw.count)
        let valence = valenceRaw.reduce(0, +) / Double(valenceRaw.count)
        return (arousal, valence)
    }

    private func computeEmotion() -> EmotionState {
        let (arousal, valence) = computeScores()

        switch (arousal > 3.0, valence > 3.0) {
        case (true, true):   return .energetic  // Yüksek enerji + iyi his
        case (true, false):  return .stressed   // Yüksek enerji + kötü his
        case (false, true):  return .calm       // Düşük enerji + iyi his
        case (false, false): return .stressed   // Düşük enerji + kötü his (tükenmiş stres)
        }
    }

    // MARK: - Navigasyon

    private func advance() {
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            let emotion = computeEmotion()
            result = emotion
            HapticManager.notification(.success)
            withAnimation { showingResult = true }
        }
    }
}

// MARK: - Yardımcı Bileşenler

private struct ScoreChip: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.1f", value))
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - EmotionState Uzantıları

private extension EmotionState {
    var resultDescription: String {
        switch self {
        case .calm:
            return "Enerji seviyenin düşük ve duygu durumun olumlu. Zihnin huzurlu, sakin bir yaratıcılık için harika bir an."
        case .energetic:
            return "Hem enerji seviyenin hem de duygu durumunun yüksek olduğunu görüyoruz. Dinamik ve akışkan çizimler için ideal."
        case .stressed:
            return "Gerginlik veya tükenme belirtileri mevcut. Çizmek bu duyguları dışa vurman için iyi bir yol olabilir."
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
