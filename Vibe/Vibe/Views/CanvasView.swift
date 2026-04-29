import SwiftUI
import PencilKit
import UIKit

struct CanvasView: View {
    @StateObject private var biometricService = BiometricService()
    @StateObject private var drawingEngine = DrawingEngine()
    @State private var canvasView = PKCanvasView()
    @State private var isShowingMoodInput = false
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var emotionPulse = false

    var body: some View {
        ZStack(alignment: .top) {
            // Arkaplan — duyguya göre renk geçişi
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                biometricService.currentEmotion.color
                    .opacity(0.07)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: biometricService.currentEmotion)
            }

            // Çizim Alanı
            PKCanvasViewWrapper(canvasView: $canvasView, drawingEngine: drawingEngine)
                .ignoresSafeArea(edges: .bottom)

            // Üst Bar
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    // BPM / Manuel Mod Butonu
                    Button {
                        isShowingMoodInput.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: biometricService.isMocking ? "hand.point.up" : "heart.fill")
                                .foregroundColor(biometricService.isMocking ? .orange : .red)
                                .symbolEffect(.pulse, isActive: !biometricService.isMocking)
                            Text(biometricService.isMocking ? "Manuel" : "\(biometricService.currentBPM) BPM")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }

                    Spacer()

                    // Duygu Durumu
                    HStack(spacing: 6) {
                        Text(biometricService.currentEmotion.emoji)
                            .font(.title3)
                            .scaleEffect(emotionPulse ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: emotionPulse)

                        Text(biometricService.currentEmotion.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(biometricService.currentEmotion.color)
                            .animation(.easeInOut(duration: 0.3), value: biometricService.currentEmotion)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .cornerRadius(12)

                    Spacer()

                    // Undo / Redo
                    HStack(spacing: 12) {
                        Button {
                            canvasView.undoManager?.undo()
                            updateUndoState()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(canUndo ? .primary : .secondary.opacity(0.4))
                        }
                        .disabled(!canUndo)

                        Button {
                            canvasView.undoManager?.redo()
                            updateUndoState()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(canRedo ? .primary : .secondary.opacity(0.4))
                        }
                        .disabled(!canRedo)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .cornerRadius(12)

                    // Temizle
                    Button {
                        withAnimation {
                            canvasView.drawing = PKDrawing()
                            DrawingStore.shared.clear()
                            updateUndoState()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // Renk Paleti
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(drawingEngine.availableColors, id: \.self) { color in
                            let isSelected = drawingEngine.selectedColor == color

                            Circle()
                                .fill(color)
                                .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: isSelected ? 2.5 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: isSelected ? 1.5 : 0)
                                        .padding(2.5)
                                )
                                .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        drawingEngine.selectColor(color)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            if let savedDrawing = DrawingStore.shared.load() {
                canvasView.drawing = savedDrawing
            }
            biometricService.requestAuthorization()
            updateUndoState()
        }
        .onChange(of: biometricService.currentEmotion) { _, newEmotion in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                drawingEngine.updateForEmotion(newEmotion)
            }
            emotionPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emotionPulse = false
            }
        }
        .sheet(isPresented: $isShowingMoodInput) {
            MoodInputView(biometricService: biometricService)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerCheckpoint)) { _ in
            updateUndoState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in
            updateUndoState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in
            updateUndoState()
        }
    }

    private func updateUndoState() {
        DispatchQueue.main.async {
            self.canUndo = canvasView.undoManager?.canUndo ?? false
            self.canRedo = canvasView.undoManager?.canRedo ?? false
        }
    }
}
