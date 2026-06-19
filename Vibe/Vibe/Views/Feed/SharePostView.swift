import SwiftUI
import PencilKit
import UIKit

struct SharePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var feedService = FeedService.shared

    let drawing: PKDrawing
    let emotion: EmotionState
    let bpm: Int
    let bgType: CanvasBgType
    let bgColor: UIColor

    @State private var caption = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil
    @FocusState private var captionFocused: Bool

    /// Çizimi, arka plan rengi ve desen (kare/çizgili) ile birlikte birleştirir.
    private var thumbnail: UIImage? {
        let drawingBounds = drawing.strokes.isEmpty
            ? CGRect(x: 0, y: 0, width: 400, height: 400)
            : drawing.bounds.insetBy(dx: -30, dy: -30)

        let renderer = UIGraphicsImageRenderer(bounds: drawingBounds)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // 1. Arka plan rengini doldur
            bgColor.setFill()
            cgCtx.fill(drawingBounds)

            // 2. Desen çiz (grid / lined)
            if bgType != .blank {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                bgColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                let brightness = (r * 299 + g * 587 + b * 114) / 1000
                let strokeColor = brightness < 0.5 ? UIColor.white.withAlphaComponent(0.08) : UIColor.black.withAlphaComponent(0.12)
                strokeColor.setStroke()
                cgCtx.setLineWidth(0.5)

                if bgType == .grid {
                    let spacing: CGFloat = 24
                    let cols = Int(ceil(drawingBounds.width  / spacing))
                    let rows = Int(ceil(drawingBounds.height / spacing))
                    for i in 0...cols {
                        let x = drawingBounds.minX + CGFloat(i) * spacing
                        cgCtx.move(to: CGPoint(x: x, y: drawingBounds.minY))
                        cgCtx.addLine(to: CGPoint(x: x, y: drawingBounds.maxY))
                    }
                    for i in 0...rows {
                        let y = drawingBounds.minY + CGFloat(i) * spacing
                        cgCtx.move(to: CGPoint(x: drawingBounds.minX, y: y))
                        cgCtx.addLine(to: CGPoint(x: drawingBounds.maxX, y: y))
                    }
                } else { // .lined
                    let spacing: CGFloat = 30
                    let rows = Int(ceil(drawingBounds.height / spacing))
                    for i in 0...rows {
                        let y = drawingBounds.minY + CGFloat(i) * spacing
                        cgCtx.move(to: CGPoint(x: drawingBounds.minX, y: y))
                        cgCtx.addLine(to: CGPoint(x: drawingBounds.maxX, y: y))
                    }
                }
                cgCtx.strokePath()
            }

            // 3. PencilKit çizimlerini üstüne çiz
            let strokesImage = drawing.image(from: drawingBounds, scale: UIScreen.main.scale)
            strokesImage.draw(in: drawingBounds)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {

                    // Önizleme
                    previewCard
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)

                    // Kullanıcı + duygu
                    userRow
                        .padding(.horizontal, AppSpacing.lg)

                    // Açıklama alanı
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "AÇIKLAMA")
                        captionField
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Hata
                    if let errorMessage {
                        errorBanner(errorMessage)
                            .padding(.horizontal, AppSpacing.lg)
                    }

                    Spacer(minLength: 60)
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Akışa Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: isPosting ? "Paylaşılıyor..." : "Paylaş",
                    icon: "paperplane.fill",
                    isLoading: isPosting,
                    color: emotion.color
                ) {
                    sharePost()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(AppColor.canvas)
            }
        }
    }

    // MARK: - Önizleme

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(emotion.color.opacity(0.06))

            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(AppSpacing.md)
            }
        }
        .frame(maxHeight: 280)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(emotion.color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Kullanıcı Satırı

    private var userRow: some View {
        HStack(spacing: 12) {
            if let user = authService.socialUser {
                avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("Akışa paylaşılacak")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.inkMuted)
                }
            }

            Spacer()

            // Duygu rozeti
            HStack(spacing: 5) {
                Text(emotion.emoji)
                Text(emotion.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(emotion.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(emotion.color.opacity(0.10))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(emotion.color.opacity(0.20), lineWidth: 1))
        }
    }

    // MARK: - Açıklama Alanı

    private var captionField: some View {
        TextField("Bu çizim hakkında bir şeyler yaz...", text: $caption, axis: .vertical)
            .focused($captionFocused)
            .font(.system(size: 15))
            .lineLimit(3...6)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        captionFocused ? emotion.color.opacity(0.40) : AppColor.divider,
                        lineWidth: captionFocused ? 1.5 : 0.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: captionFocused)
    }

    // MARK: - Hata Banner

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(AppColor.ink)
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    // MARK: - Aksiyon

    private func sharePost() {
        guard let user = authService.socialUser, let image = thumbnail else { return }
        isPosting = true
        HapticManager.impact(.medium)
        feedService.sharePost(image: image, emotion: emotion, bpm: bpm, caption: caption, user: user) { error in
            isPosting = false
            if let error {
                errorMessage = error.localizedDescription
            } else {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}
