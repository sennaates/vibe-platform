import SwiftUI
import PencilKit

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @EnvironmentObject var authService: AuthService
    @ObservedObject var galleryStore: GalleryStore

    @State private var isShowingStats = false
    @State private var selectedRecord: DrawingRecord?
    @State private var shareRecord: DrawingRecord?   // "Akışa paylaş" hedefi

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if galleryStore.records.isEmpty {
                    emptyView
                } else {
                    grid
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Galeri")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.impact(.light)
                        isShowingStats = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(AppColor.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .sheet(isPresented: $isShowingStats) {
                StatsView(galleryStore: galleryStore)
                    .environmentObject(authService)
            }
            .sheet(item: $selectedRecord) { record in
                DrawingDetailView(record: record)
            }
            .sheet(item: $shareRecord) { record in
                SharePostView(
                    drawing:  record.drawing ?? PKDrawing(),
                    emotion:  record.emotion,
                    bpm:      record.bpmHistory.last?.bpm ?? 72,
                    bgType:   record.bgType,
                    bgColor:  record.bgUIColor
                )
                .environmentObject(authService)
            }
        }
    }

    // MARK: - Boş

    private var emptyView: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "scribble.variable",
                title: "Henüz çizim yok",
                message: "Kanvas ekranındaki ↓ butonuyla çizimlerini galeriye kaydedebilirsin."
            )
            Spacer()
        }
    }

    // MARK: - Grid

    private var grid: some View {
        ScrollView {
            // Üst sayaç
            HStack {
                Text("\(galleryStore.records.count) çizim")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.inkMuted)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, 4)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(galleryStore.records) { record in
                    GalleryCard(record: record,
                                onShare: { shareRecord = record },
                                onDelete: { galleryStore.delete(record: record) })
                    .onTapGesture {
                        HapticManager.impact(.light)
                        selectedRecord = record
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Galeri Kartı

private struct GalleryCard: View {
    let record: DrawingRecord
    let onShare: () -> Void      // Akışa paylaş
    let onDelete: () -> Void

    @State private var shareImage: UIImage?
    @State private var isShowingSystemShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Önizleme
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(record.emotion.color.opacity(0.06))

                if let thumbnail = record.thumbnail() {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "scribble")
                        .font(.title)
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(record.emotion.color.opacity(0.15), lineWidth: 1)
            )

            // Bilgi + Hızlı paylaş butonu
            HStack(spacing: 5) {
                Text(record.emotion.emoji).font(.system(size: 12))
                Text(record.emotion.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(record.emotion.color)
                Spacer()
                // Akışa paylaş ikonu
                Button {
                    HapticManager.impact(.light)
                    onShare()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.accent)
                        .padding(6)
                        .background(AppColor.accent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .contextMenu {
            // Akışa paylaş
            Button {
                HapticManager.impact(.light)
                onShare()
            } label: {
                Label("Akışa Paylaş", systemImage: "paperplane")
            }

            // Sistem paylaşım
            Button {
                if let img = record.thumbnail(size: CGSize(width: 1200, height: 900)) {
                    shareImage = img
                    isShowingSystemShare = true
                }
            } label: {
                Label("Görsel Olarak Paylaş", systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .sheet(isPresented: $isShowingSystemShare) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
