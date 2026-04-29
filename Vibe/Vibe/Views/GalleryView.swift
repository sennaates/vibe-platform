import SwiftUI
import PencilKit

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ObservedObject var galleryStore: GalleryStore

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if galleryStore.records.isEmpty {
                    ContentUnavailableView(
                        "Henüz çizim yok",
                        systemImage: "scribble.variable",
                        description: Text("Kanvas ekranındaki ↓ butonuyla çizimlerini galeriye kaydet.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(galleryStore.records) { record in
                                GalleryCard(record: record) {
                                    galleryStore.delete(record: record)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Galeri")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

private struct GalleryCard: View {
    let record: DrawingRecord
    let onDelete: () -> Void

    @State private var shareImage: UIImage?
    @State private var isShowingShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Önizleme
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(record.emotion.color.opacity(0.08))

                if let thumbnail = record.thumbnail() {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "scribble")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Bilgi satırı
            HStack(spacing: 6) {
                Text(record.emotion.emoji)
                    .font(.caption)
                Text(record.emotion.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(record.emotion.color)
                Spacer()
                Text(record.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button {
                if let img = record.thumbnail(size: CGSize(width: 1200, height: 900)) {
                    shareImage = img
                    isShowingShare = true
                }
            } label: {
                Label("Paylaş", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .sheet(isPresented: $isShowingShare) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
