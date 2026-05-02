import SwiftUI
import Charts

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var galleryStore: GalleryStore

    private var emotionCounts: [(emotion: EmotionState, count: Int)] {
        let all = EmotionState.allCases.filter { $0 != .unknown }
        return all.map { emotion in
            (emotion, galleryStore.records.filter { $0.emotion == emotion }.count)
        }.filter { $0.count > 0 }
    }

    private var totalDrawings: Int { galleryStore.records.count }

    private var dominantEmotion: EmotionState? {
        emotionCounts.max(by: { $0.count < $1.count })?.emotion
    }

    private var streakDays: Int {
        guard !galleryStore.records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDates = galleryStore.records
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
        var streak = 1
        var current = sortedDates[0]
        for date in sortedDates.dropFirst() {
            let diff = calendar.dateComponents([.day], from: date, to: current).day ?? 0
            if diff == 1 { streak += 1; current = date }
            else if diff > 1 { break }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            Group {
                if totalDrawings == 0 {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "Henüz istatistik yok",
                            message: "Çizim yapıp galeriye kaydettikçe istatistiklerin burada görünür."
                        )
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            summaryCards
                            if !emotionCounts.isEmpty { emotionBarChart }
                            weeklyActivity
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
        }
    }

    // MARK: - Özet kartları

    private var summaryCards: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(totalDrawings)", label: "Toplam Çizim",
                     icon: "scribble", color: AppColor.accent)

            StatCard(value: "\(streakDays)", label: "Gün Serisi",
                     icon: "flame.fill", color: .orange)

            if let dominant = dominantEmotion {
                StatCard(value: dominant.emoji, label: "En Sık",
                         icon: nil, color: dominant.color)
            }
        }
    }

    // MARK: - Bar chart

    private var emotionBarChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("Duygu Dağılımı", subtitle: "Hangi duygularla ne kadar çizdin")

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
                .frame(height: 180)

                HStack(spacing: 14) {
                    ForEach(emotionCounts, id: \.emotion) { item in
                        HStack(spacing: 4) {
                            Text(item.emotion.emoji).font(.system(size: 13))
                            Text(item.emotion.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Haftalık aktivite

    private var weeklyActivity: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                SectionHeader("Son 7 Gün", subtitle: "Çizim sıklığın")

                let days = last7Days()
                let maxCount = max(days.map(\.count).max() ?? 1, 1)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(days, id: \.date) { day in
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppColor.surfaceMuted)
                                    .frame(height: 100)

                                if day.count > 0 {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColor.accent.gradient)
                                        .frame(height: max(14, CGFloat(day.count) / CGFloat(maxCount) * 100))
                                        .overlay(alignment: .top) {
                                            Text("\(day.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.top, 3)
                                        }
                                }
                            }
                            Text(day.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func last7Days() -> [(date: Date, label: String, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let count = galleryStore.records.filter {
                calendar.startOfDay(for: $0.date) == date
            }.count
            let label = offset == 0 ? "Bugün" : calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            return (date, label, count)
        }
    }
}

// MARK: - Stat Kartı

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String?
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            Text(value)
                .font(icon == nil
                      ? .system(size: 32)
                      : .system(size: 22, weight: .bold))
                .foregroundColor(icon == nil ? AppColor.ink : color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}
