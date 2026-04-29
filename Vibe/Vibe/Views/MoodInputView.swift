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
            VStack(spacing: 24) {

                // Bilimsel test kartı
                Button {
                    isShowingTest = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Psikolojik Test")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Russell Circumplex modeline dayalı 5 soruluk bilimsel ölçüm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Divider().padding(.horizontal)

                // Manuel slider
                VStack(spacing: 16) {
                    Text("Manuel Ayarlama")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        Text(currentEmotion.emoji)
                            .font(.system(size: 64))
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentEmotion)

                        Text(currentEmotion.displayName)
                            .font(.title2.weight(.semibold))
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
                        RoundedRectangle(cornerRadius: 18)
                            .fill(currentEmotion.color.opacity(0.1))
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentEmotion)
                    .padding(.horizontal)

                    VStack(spacing: 10) {
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
                }

                Button {
                    biometricService.enableMockMode()
                    biometricService.setMockBPM(Int(sliderValue))
                    dismiss()
                } label: {
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
            .sheet(isPresented: $isShowingTest) {
                MoodTestView(biometricService: biometricService, onApply: { dismiss() })
            }
        }
        .onAppear {
            sliderValue = Double(biometricService.currentBPM)
        }
    }
}
