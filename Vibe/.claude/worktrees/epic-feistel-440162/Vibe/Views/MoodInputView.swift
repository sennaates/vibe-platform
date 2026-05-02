import SwiftUI

struct MoodInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var biometricService: BiometricService

    @State private var sliderValue: Double = 65

    private var currentEmotion: EmotionState {
        EmotionClassifier.classify(bpm: Int(sliderValue))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Şu an nasıl hissediyorsun?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(currentEmotion.emoji)
                        .font(.system(size: 80))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentEmotion)

                    Text(currentEmotion.displayName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(currentEmotion.color)
                        .animation(.easeInOut(duration: 0.3), value: currentEmotion)

                    Text("\(Int(sliderValue)) BPM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(currentEmotion.color.opacity(0.1))
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentEmotion)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Slider(value: $sliderValue, in: 40...140, step: 1)
                        .tint(currentEmotion.color)
                        .animation(.easeInOut(duration: 0.2), value: currentEmotion)

                    HStack {
                        Label("Sakin", systemImage: "leaf")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Label("Enerjik", systemImage: "bolt")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Label("Stresli", systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    biometricService.enableMockMode()
                    biometricService.setMockBPM(Int(sliderValue))
                    dismiss()
                }) {
                    Text("Uygula")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentEmotion.color)
                        .cornerRadius(14)
                        .animation(.easeInOut(duration: 0.3), value: currentEmotion)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Duygu Durumu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .onAppear {
            sliderValue = Double(biometricService.currentBPM)
        }
    }
}
