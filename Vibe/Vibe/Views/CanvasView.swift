import SwiftUI
import PencilKit
import UIKit

struct CanvasView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss

    let user: UserProfile

    @StateObject private var biometricService = BiometricService()
    @StateObject private var drawingEngine = DrawingEngine()
    @StateObject private var galleryStore: GalleryStore
    @State private var canvasView = PKCanvasView()
    @State private var isShowingMoodInput = false
    @State private var isShowingGallery = false
    @State private var isShowingShare = false
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var emotionPulse = false
    @State private var savedFeedback = false

    private let drawingStore: DrawingStore

    init(user: UserProfile) {
        self.user = user
        _galleryStore = StateObject(wrappedValue: GalleryStore(userId: user.id))
        self.drawingStore = DrawingStore(userId: user.id)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Arkaplan
            Color(UIColor.systemBackground).ignoresSafeArea()
            biometricService.currentEmotion.color
                .opacity(0.07)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: biometricService.currentEmotion)

            // Çizim alanı
            PKCanvasViewWrapper(canvasView: $canvasView, drawingEngine: drawingEngine, drawingStore: drawingStore)
                .ignoresSafeArea(edges: .bottom)

            // "Kaydedildi" toast
            if savedFeedback {
                VStack {
                    Spacer()
                    Label("Galeriye kaydedildi", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .shadow(radius: 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
            }

            // Üst kontrol alanı
            VStack(spacing: 0) {
                if sizeClass == .regular {
                    iPadTopBar
                } else {
                    iPhoneTopBar
                }
                colorPalette
            }
        }
        .onAppear {
            if let saved = drawingStore.load() {
                canvasView.drawing = saved
            }
            biometricService.requestAuthorization()
            updateUndoState()
        }
        .onChange(of: biometricService.currentEmotion) { _, newEmotion in
            HapticManager.impact(.medium)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                drawingEngine.updateForEmotion(newEmotion)
            }
            emotionPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { emotionPulse = false }
        }
        .sheet(isPresented: $isShowingMoodInput) {
            MoodInputView(biometricService: biometricService)
        }
        .sheet(isPresented: $isShowingGallery) {
            GalleryView(galleryStore: galleryStore)
        }
        .sheet(isPresented: $isShowingShare) {
            SharePostView(drawing: canvasView.drawing, emotion: biometricService.currentEmotion)
                .environmentObject(AuthService.shared)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerCheckpoint)) { _ in updateUndoState() }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in updateUndoState() }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in updateUndoState() }
    }

    // MARK: - iPhone Top Bar (3 öğe: Avatar+Geri | Duygu | Menü)

    private var iPhoneTopBar: some View {
        HStack(spacing: 10) {
            // Kullanıcı avatarı + geri
            Button { dismiss() } label: {
                HStack(spacing: 8) {
                    avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 30)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.regularMaterial)
                .cornerRadius(12)
            }

            Spacer()

            emotionBadge

            Spacer()

            // Eylemler menüsü
            Menu {
                Button { isShowingMoodInput.toggle() } label: {
                    Label(
                        biometricService.isMocking ? "Manuel Mod" : "\(biometricService.currentBPM) BPM",
                        systemImage: biometricService.isMocking ? "hand.point.up" : "heart.fill"
                    )
                }

                Divider()

                Button { canvasView.undoManager?.undo(); updateUndoState() } label: {
                    Label("Geri Al", systemImage: "arrow.uturn.backward")
                }
                .disabled(!canUndo)

                Button { canvasView.undoManager?.redo(); updateUndoState() } label: {
                    Label("İleri Al", systemImage: "arrow.uturn.forward")
                }
                .disabled(!canRedo)

                Divider()

                Button { saveToGallery() } label: {
                    Label("Galeriye Kaydet", systemImage: "square.and.arrow.down")
                }

                Button { isShowingGallery = true } label: {
                    Label("Galeriyi Aç", systemImage: "photo.stack")
                }

                Button { isShowingShare = true } label: {
                    Label("Akışa Paylaş", systemImage: "paperplane")
                }

                Divider()

                Button(role: .destructive) {
                    HapticManager.notification(.warning)
                    canvasView.drawing = PKDrawing()
                    drawingStore.clear()
                    updateUndoState()
                } label: {
                    Label("Tuvali Temizle", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - iPad Top Bar

    private var iPadTopBar: some View {
        HStack(spacing: 12) {
            // Kullanıcı avatarı + geri + BPM
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 28)
                        Text(user.name)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }

                bpmButton
            }

            Spacer()

            emotionBadge

            Spacer()

            HStack(spacing: 8) {
                iconButton("arrow.uturn.backward", enabled: canUndo) {
                    canvasView.undoManager?.undo(); updateUndoState()
                }
                iconButton("arrow.uturn.forward", enabled: canRedo) {
                    canvasView.undoManager?.redo(); updateUndoState()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .cornerRadius(12)

            iconButton("photo.stack") { isShowingGallery = true }
            iconButton("square.and.arrow.down") { saveToGallery() }
            iconButton("trash") {
                canvasView.drawing = PKDrawing()
                drawingStore.clear()
                updateUndoState()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Renk Paleti + Araçlar

    private var colorPalette: some View {
        VStack(spacing: 0) {
            // Renkler + Silgi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Silgi butonu
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            drawingEngine.toggleEraser()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(drawingEngine.isEraserActive
                                      ? Color.primary
                                      : Color(UIColor.secondarySystemBackground))
                                .frame(width: 34, height: 34)
                            Image(systemName: "eraser.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(drawingEngine.isEraserActive ? Color(UIColor.systemBackground) : .primary)
                        }
                        .shadow(color: drawingEngine.isEraserActive ? Color.primary.opacity(0.3) : .clear, radius: 6)
                    }

                    Divider().frame(height: 28)

                    ForEach(drawingEngine.availableColors, id: \.self) { color in
                        let isSelected = drawingEngine.selectedColor == color && !drawingEngine.isEraserActive
                        Circle()
                            .fill(color)
                            .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)
                            .overlay(Circle().stroke(Color.primary, lineWidth: isSelected ? 2.5 : 0))
                            .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 1.5 : 0).padding(2.5))
                            .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                            .onTapGesture {
                                HapticManager.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    drawingEngine.selectColor(color)
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Fırça boyutu
            HStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
                Slider(
                    value: Binding(
                        get: { drawingEngine.brushSize },
                        set: { drawingEngine.setBrushSize($0) }
                    ),
                    in: 1...40,
                    step: 1
                )
                .tint(drawingEngine.isEraserActive ? .primary : drawingEngine.selectedColor)
                Image(systemName: "circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Ortak Parçalar

    private var bpmButton: some View {
        Button { isShowingMoodInput.toggle() } label: {
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
    }

    private var emotionBadge: some View {
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
    }

    private func iconButton(_ icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(enabled ? .primary : .secondary.opacity(0.4))
                .padding(10)
                .background(.regularMaterial)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }

    // MARK: - Actions

    private func saveToGallery() {
        guard !canvasView.drawing.strokes.isEmpty else {
            HapticManager.notification(.warning)
            return
        }
        galleryStore.save(drawing: canvasView.drawing, emotion: biometricService.currentEmotion)
        HapticManager.notification(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { savedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedFeedback = false }
        }
    }

    private func updateUndoState() {
        DispatchQueue.main.async {
            self.canUndo = canvasView.undoManager?.canUndo ?? false
            self.canRedo = canvasView.undoManager?.canRedo ?? false
        }
    }
}
