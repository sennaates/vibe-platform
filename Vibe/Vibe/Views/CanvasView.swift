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
            biometricService.startSession()
            updateUndoState()
        }
        .onDisappear {
            biometricService.stopSession()
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
            // Avatar + geri
            Button { dismiss() } label: {
                HStack(spacing: 8) {
                    avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 28)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.inkMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColor.surface)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(AppColor.divider, lineWidth: 0.5))
            }

            Spacer()

            emotionBadge

            Spacer()

            // Menü
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
                }.disabled(!canUndo)
                Button { canvasView.undoManager?.redo(); updateUndoState() } label: {
                    Label("İleri Al", systemImage: "arrow.uturn.forward")
                }.disabled(!canRedo)
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
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .frame(width: 36, height: 36)
                    .background(AppColor.surface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppColor.divider, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - iPad Top Bar

    private var iPadTopBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 26)
                        Text(user.name)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppColor.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColor.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(AppColor.divider, lineWidth: 0.5))
                }

                bpmButton
            }

            Spacer()
            emotionBadge
            Spacer()

            HStack(spacing: 6) {
                iconButton("arrow.uturn.backward", enabled: canUndo) {
                    canvasView.undoManager?.undo(); updateUndoState()
                }
                iconButton("arrow.uturn.forward", enabled: canRedo) {
                    canvasView.undoManager?.redo(); updateUndoState()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(AppColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppColor.divider, lineWidth: 0.5))

            iconButton("photo.stack") { isShowingGallery = true }
            iconButton("square.and.arrow.down") { saveToGallery() }
            iconButton("paperplane") { isShowingShare = true }
            iconButton("trash") {
                canvasView.drawing = PKDrawing()
                drawingStore.clear()
                updateUndoState()
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Renk Paleti + Araçlar

    private var colorPalette: some View {
        VStack(spacing: 0) {
            // İnce ayraç çizgisi (üstte)
            Rectangle()
                .fill(AppColor.divider)
                .frame(height: 0.5)

            // Renkler + Silgi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Silgi
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            drawingEngine.toggleEraser()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(drawingEngine.isEraserActive
                                      ? AppColor.ink
                                      : AppColor.surfaceMuted)
                                .frame(width: 34, height: 34)
                            Image(systemName: "eraser.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(drawingEngine.isEraserActive ? AppColor.canvas : AppColor.ink)
                        }
                        .shadow(color: drawingEngine.isEraserActive ? AppColor.ink.opacity(0.25) : .clear, radius: 6)
                    }

                    Rectangle()
                        .fill(AppColor.divider)
                        .frame(width: 1, height: 24)
                        .padding(.horizontal, 4)

                    ForEach(drawingEngine.availableColors, id: \.self) { color in
                        let isSelected = drawingEngine.selectedColor == color && !drawingEngine.isEraserActive
                        Circle()
                            .fill(color)
                            .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)
                            .overlay(Circle().strokeBorder(AppColor.canvas, lineWidth: isSelected ? 2 : 0))
                            .overlay(Circle().strokeBorder(color.opacity(0.9), lineWidth: isSelected ? 1 : 0).padding(2))
                            .shadow(color: isSelected ? color.opacity(0.55) : .clear, radius: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                            .onTapGesture {
                                HapticManager.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    drawingEngine.selectColor(color)
                                }
                            }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 10)
            }

            // Fırça boyutu — daha minimal
            HStack(spacing: 10) {
                Circle()
                    .fill(AppColor.inkMuted)
                    .frame(width: 4, height: 4)
                Slider(
                    value: Binding(
                        get: { drawingEngine.brushSize },
                        set: { drawingEngine.setBrushSize($0) }
                    ),
                    in: 1...40,
                    step: 1
                )
                .tint(drawingEngine.isEraserActive ? AppColor.ink : drawingEngine.selectedColor)
                Circle()
                    .fill(AppColor.inkMuted)
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, 10)
            .padding(.top, 2)
        }
        .background(AppColor.canvas.opacity(0.95))
        .background(.ultraThinMaterial)
    }

    // MARK: - Ortak Parçalar

    private var bpmButton: some View {
        Button { isShowingMoodInput.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: biometricService.isMocking ? "hand.point.up" : "heart.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(biometricService.isMocking ? AppColor.accent : Color(red: 0.85, green: 0.30, blue: 0.30))
                    .symbolEffect(.pulse, isActive: !biometricService.isMocking)
                Text(biometricService.isMocking ? "Manuel" : "\(biometricService.currentBPM)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .monospacedDigit()
                if !biometricService.isMocking {
                    Text("BPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppColor.divider, lineWidth: 0.5))
        }
    }

    private var emotionBadge: some View {
        HStack(spacing: 6) {
            Text(biometricService.currentEmotion.emoji)
                .font(.system(size: 16))
                .scaleEffect(emotionPulse ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: emotionPulse)
            Text(biometricService.currentEmotion.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(biometricService.currentEmotion.color)
                .animation(.easeInOut(duration: 0.3), value: biometricService.currentEmotion)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(biometricService.currentEmotion.color.opacity(0.10))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(biometricService.currentEmotion.color.opacity(0.25), lineWidth: 0.8))
    }

    private func iconButton(_ icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(enabled ? AppColor.ink : AppColor.inkMuted.opacity(0.4))
                .frame(width: 36, height: 36)
                .background(AppColor.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColor.divider, lineWidth: 0.5))
        }
        .disabled(!enabled)
    }

    // MARK: - Actions

    private func saveToGallery() {
        guard !canvasView.drawing.strokes.isEmpty else {
            HapticManager.notification(.warning)
            return
        }
        let bpmHistory = biometricService.snapshotBpmHistory()
        galleryStore.save(drawing: canvasView.drawing, emotion: biometricService.currentEmotion, bpmHistory: bpmHistory)
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
