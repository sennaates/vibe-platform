import SwiftUI
import Charts
import FirebaseFirestore

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @ObservedObject var galleryStore: GalleryStore

    // Firestore'dan yüklenen paylaşılan gönderi istatistikleri
    @State private var posts: [Post] = []
    @State private var isLoadingPosts = true

    // MARK: - Yerel galeri hesaplamaları (local PencilKit)

    private var emotionCounts: [(emotion: EmotionState, count: Int)] {
        EmotionState.allCases.filter { $0 != .unknown }
            .map { e in (e, galleryStore.records.filter { $0.emotion == e }.count) }
            .filter { $0.count > 0 }
    }

    private var localStreak: Int {
        guard !galleryStore.records.isEmpty else { return 0 }
        let cal = Calendar.current
        let sorted = galleryStore.records
            .map { cal.startOfDay(for: $0.date) }.sorted(by: >)
        var streak = 1; var cur = sorted[0]
        for date in sorted.dropFirst() {
            guard cal.dateComponents([.day], from: date, to: cur).day == 1 else { break }
            streak += 1; cur = date
        }
        return streak
    }

    // MARK: - Firestore hesaplamaları

    private var totalLikes:    Int { posts.reduce(0) { $0 + $1.likeCount } }
    private var totalComments: Int { posts.reduce(0) { $0 + $1.commentCount } }
    private var avgBpm: Int {
        guard !posts.isEmpty else { return 0 }
        return posts.reduce(0) { $0 + $1.bpm } / posts.count
    }
    private var maxBpm: Int { posts.map(\.bpm).max() ?? 0 }
    private var minBpm: Int { posts.map(\.bpm).min() ?? 0 }

    private var dominantEmotion: EmotionState? {
        emotionCounts.max(by: { $0.count < $1.count })?.emotion
    }

    private var bestPost: Post? {
        posts.max(by: { $0.likeCount < $1.likeCount })
    }

    private var topTags: [(tag: String, count: Int)] {
        var map: [String: Int] = [:]
        posts.forEach { $0.extractedTags.forEach { map[$0, default: 0] += 1 } }
        return map.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }.prefix(10).map { $0 }
    }

    // Son 30 post BPM verisi (kronolojik)
    private var bpmSeries: [(index: Int, bpm: Int)] {
        Array(posts.reversed().suffix(30).enumerated().map { (i, p) in (i + 1, p.bpm) })
    }

    // MARK: - Aktivite haritası (son 84 gün = 12 hafta)

    private struct HeatCell: Identifiable {
        let id: String; let count: Int
        var level: Int { count == 0 ? 0 : count == 1 ? 1 : count <= 2 ? 2 : 3 }
    }

    private var heatCells: [HeatCell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var dayMap: [String: Int] = [:]
        posts.forEach { p in
            let key = cal.startOfDay(for: p.createdAt).formatted(.iso8601.year().month().day())
            dayMap[key, default: 0] += 1
        }
        return (0..<84).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: today)!
            let key = cal.startOfDay(for: d).formatted(.iso8601.year().month().day())
            return HeatCell(id: key, count: dayMap[key] ?? 0)
        }
    }

    // Haftanın günleri dağılımı
    private var dayOfWeekData: [(label: String, count: Int)] {
        let labels = ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
        var map = [Int: Int]()
        posts.forEach {
            let wd = Calendar.current.component(.weekday, from: $0.createdAt) - 1
            map[wd, default: 0] += 1
        }
        return labels.enumerated().map { (i, l) in (l, map[i] ?? 0) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingPosts {
                    VStack { Spacer(); ProgressView().tint(AppColor.accent); Spacer() }
                } else if posts.isEmpty && galleryStore.records.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "Henüz istatistik yok",
                            message: "Çizim paylaştıkça istatistiklerin burada görünür."
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {

                            // ── Sosyal özet kartları ───────────────────────
                            if !posts.isEmpty {
                                socialSummaryCards
                                if bpmSeries.count > 1 { bpmChart }
                                activityHeatmap
                                dayOfWeekChart
                                if !topTags.isEmpty { topHashtags }
                                if let bp = bestPost, bp.likeCount > 0 { bestPostCard(bp) }
                            }

                            // ── Yerel galeri (PencilKit) istatistikleri ───
                            if !emotionCounts.isEmpty {
                                localGallerySection
                            }
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
            .onAppear { fetchPosts() }
        }
    }

    // MARK: - Sosyal özet kartları

    private var socialSummaryCards: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 10) {
                StatCard(value: "\(posts.count)",    label: "Paylaşım",    icon: "scribble",    color: AppColor.accent)
                StatCard(value: "\(totalLikes)",     label: "Beğeni",      icon: "heart.fill",   color: .red)
                StatCard(value: "\(totalComments)",  label: "Yorum",       icon: "bubble.left",  color: Color(hex: "#6366f1"))
                StatCard(value: localStreak > 0 ? "\(localStreak)g" : "—", label: "Seri",
                         icon: "flame.fill", color: .orange)
            }
            HStack(spacing: 10) {
                if let d = dominantEmotion {
                    StatCard(value: d.emoji, label: "Dominant", icon: nil, color: d.color)
                }
                StatCard(value: "\(avgBpm)", label: "Ort. BPM", icon: "waveform.path.ecg", color: Color(hex: "#C45F8A"))
                StatCard(value: "\(minBpm)–\(maxBpm)", label: "BPM Aralığı", icon: "bolt.fill", color: AppColor.accent)
            }
        }
    }

    // MARK: - BPM Grafiği

    private var bpmChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("BPM Geçmişi", subtitle: "Son \(bpmSeries.count) paylaşım")

                Chart(bpmSeries, id: \.index) { item in
                    AreaMark(
                        x: .value("Gönderi", item.index),
                        yStart: .value("Min", 40),
                        yEnd: .value("BPM", item.bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColor.accent.opacity(0.25), AppColor.accent.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Gönderi", item.index),
                        y: .value("BPM", item.bpm)
                    )
                    .foregroundStyle(AppColor.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Gönderi", item.index),
                        y: .value("BPM", item.bpm)
                    )
                    .foregroundStyle(AppColor.accent)
                    .symbolSize(25)
                }
                .chartYScale(domain: 40...180)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [60, 100, 140, 180]) { v in
                        AxisValueLabel { Text("\(v.as(Int.self) ?? 0)").font(.system(size: 10)) }
                        AxisGridLine(stroke: StrokeStyle(dash: [4]))
                    }
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: - Aktivite Haritası

    private var activityHeatmap: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("Aktivite Haritası", subtitle: "Son 12 hafta")

                let cols = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 12)
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(heatCells) { cell in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(heatColor(level: cell.level))
                            .frame(width: 14, height: 14)
                    }
                }

                HStack(spacing: 4) {
                    Spacer()
                    Text("Az").font(.system(size: 10)).foregroundColor(AppColor.inkSubtle)
                    ForEach(0..<4) { l in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatColor(level: l))
                            .frame(width: 12, height: 12)
                    }
                    Text("Çok").font(.system(size: 10)).foregroundColor(AppColor.inkSubtle)
                }
            }
        }
    }

    private func heatColor(level: Int) -> Color {
        switch level {
        case 0: return AppColor.surfaceMuted
        case 1: return AppColor.accent.opacity(0.25)
        case 2: return AppColor.accent.opacity(0.55)
        default: return AppColor.accent
        }
    }

    // MARK: - Haftanın Günleri

    private var dayOfWeekChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("Haftalık Alışkanlık", subtitle: "Hangi günler daha çok çiziyorsun")

                let data = dayOfWeekData
                let maxC = max(data.map(\.count).max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data, id: \.label) { day in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppColor.surfaceMuted)
                                    .frame(height: 80)

                                if day.count > 0 {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: "#C45F8A").gradient)
                                        .frame(height: max(12, CGFloat(day.count) / CGFloat(maxC) * 80))
                                        .overlay(alignment: .top) {
                                            Text("\(day.count)")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.top, 2)
                                        }
                                }
                            }
                            Text(day.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Top Hashtagler

    private var topHashtags: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("En Sık Kullandığın Hashtagler", subtitle: "\(topTags.count) etiket")

                let maxCount = topTags.first?.count ?? 1
                VStack(spacing: 12) {
                    ForEach(Array(topTags.enumerated()), id: \.element.tag) { i, item in
                        HStack(spacing: 10) {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColor.inkSubtle)
                                .frame(width: 16)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("#\(item.tag)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColor.accent)
                                    Spacer()
                                    Text("\(item.count)×")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColor.inkSubtle)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppColor.surfaceMuted)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppColor.accent.opacity(i == 0 ? 1 : 0.55))
                                            .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                    }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - En çok beğenilen gönderi

    private func bestPostCard(_ post: Post) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("En Çok Beğenilen", subtitle: "❤️ \(post.likeCount) beğeni")

                HStack(spacing: 14) {
                    AsyncImage(url: URL(string: post.imageURL)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        AppColor.surfaceMuted
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.emotion.displayName + " " + post.emotion.emoji)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                        Text("💓 \(post.bpm) BPM · 💬 \(post.commentCount) yorum")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.inkMuted)
                        if !post.caption.isEmpty {
                            Text(post.caption)
                                .font(.system(size: 11))
                                .foregroundColor(AppColor.inkSubtle)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                    Text("🏆")
                        .font(.system(size: 28))
                }
            }
        }
    }

    // MARK: - Yerel Galeri Bölümü

    private var localGallerySection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("Duygu Dağılımı", subtitle: "Yerel galeri • \(galleryStore.records.count) çizim")

                Chart(emotionCounts, id: \.emotion) { item in
                    BarMark(
                        x: .value("Duygu", item.emotion.displayName),
                        y: .value("Çizim", item.count)
                    )
                    .foregroundStyle(item.emotion.color.gradient)
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text("\(item.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(item.emotion.color)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 160)
            }
        }
    }

    // MARK: - Firestore yükleme

    private func fetchPosts() {
        guard let uid = authService.firebaseUser?.uid else {
            isLoadingPosts = false
            return
        }
        Firestore.firestore()
            .collection("posts")
            .whereField("userId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, _ in
                self.posts = snap?.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                } ?? []
                self.isLoadingPosts = false
            }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            Text(value)
                .font(icon == nil
                      ? .system(size: 28)
                      : .system(size: 18, weight: .bold))
                .foregroundColor(icon == nil ? AppColor.ink : color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColor.inkMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, 4)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}
