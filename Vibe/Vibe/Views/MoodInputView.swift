import SwiftUI

struct MoodInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var biometricService: BiometricService

    @State private var sliderValue: Double = 65
    @State private var isShowingTest = false

    private var currentEmotion: EmotionState {
        EmotionClassifier.classify(bpm: Int(sliderValue))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    // Bilimsel test kartı
                    testCard
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)

                    // Ayraç metni
                    HStack {
                        Rectangle().fill(AppColor.divider).frame(height: 1)
                        Text("VEYA")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppColor.inkMuted)
                            .padding(.horizontal, 12)
                        Rectangle().fill(AppColor.divider).frame(height: 1)
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Manuel slider
                    manualSection

                    Spacer(minLength: AppSpacing.lg)

                    // Uygula butonu
                    PrimaryButton(
                        title: "Uygula",
                        icon: "checkmark",
                        color: currentEmotion.color
                    ) {
                        biometricService.enableMockMode()
                        biometricService.setMockBPM(Int(sliderValue))
                        dismiss()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)
                    .animation(.easeInOut(duration: 0.3), value: currentEmotion)
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Duygu Durumu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .sheet(isPresented: $isShowingTest) {
                MoodTestView(biometricService: biometricService, onApply: { dismiss() })
            }
        }
        .onAppear { sliderValue = Double(biometricService.currentBPM) }
    }

    // MARK: - Test Kartı

    private var testCard: some View {
        Button {
            HapticManager.impact(.light)
            isShowingTest = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColor.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Bilimsel Duygu Testi")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("Russell Circumplex modeli — 5 soru")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.inkMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(AppColor.accent.opacity(0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manuel Bölümü

    private var manualSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Büyük emoji + duygu adı + BPM
            VStack(spacing: 10) {
                Text(currentEmotion.emoji)
                    .font(.system(size: 64))
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentEmotion)

                Text(currentEmotion.displayName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(currentEmotion.color)
                    .animation(.easeInOut(duration: 0.3), value: currentEmotion)

                Text("\(Int(sliderValue)) BPM")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.inkMuted)
                    .monospacedDigit()
            }
            .padding(.vertical, AppSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(currentEmotion.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(currentEmotion.color.opacity(0.20), lineWidth: 1)
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentEmotion)

            // Slider
            VStack(spacing: 10) {
                Slider(value: $sliderValue, in: 40...140, step: 1)
                    .tint(currentEmotion.color)
                    .animation(.easeInOut(duration: 0.2), value: currentEmotion)

                HStack {
                    zoneLabel(emoji: "🌿", text: "Sakin", color: .blue)
                    Spacer()
                    zoneLabel(emoji: "⚡", text: "Enerjik", color: .orange)
                    Spacer()
                    zoneLabel(emoji: "🔥", text: "Stresli", color: .red)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    private func zoneLabel(emoji: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
        }
    }
}
