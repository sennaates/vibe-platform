import SwiftUI
import PencilKit

struct SharePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var feedService = FeedService.shared

    let drawing: PKDrawing
    let emotion: EmotionState

    @State private var caption = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil

    private var thumbnail: UIImage? {
        let bounds = drawing.strokes.isEmpty
            ? CGRect(x: 0, y: 0, width: 400, height: 300)
            : drawing.bounds.insetBy(dx: -30, dy: -30)
        return drawing.image(from: bounds, scale: 2.0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Önizleme
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .background(emotion.color.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }

                // Duygu badge
                HStack {
                    Text(emotion.emoji)
                    Text(emotion.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(emotion.color)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(emotion.color.opacity(0.1))
                .clipShape(Capsule())

                // Açıklama
                TextField("Bir şeyler yaz... (isteğe bağlı)", text: $caption, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    sharePost()
                } label: {
                    Group {
                        if isPosting {
                            ProgressView().tint(.white)
                        } else {
                            Label("Paylaş", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(emotion.color)
                    .cornerRadius(14)
                }
                .disabled(isPosting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private func sharePost() {
        guard let user = authService.socialUser, let image = thumbnail else { return }
        isPosting = true
        HapticManager.impact(.medium)
        feedService.sharePost(image: image, emotion: emotion, caption: caption, user: user) { error in
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
