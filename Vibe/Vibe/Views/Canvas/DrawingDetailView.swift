import SwiftUI
import Charts

struct DrawingDetailView: View {
    let record: DrawingRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    drawingPreview
                    emotionHeader

                    if record.bpmHistory.count >= 2 {
                        bpmChart
                    } else {
                        noBpmView
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Çizim Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
            }
        }
    }

    // MARK: - Çizim Önizlemesi

    private var drawingPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(record.emotion.color.opacity(0.06))
                .frame(height: 260)

            if let thumbnail = record.thumbnail(size: CGSize(width: 600, height: 440)) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .padding(AppSpacing.md)
                    .frame(height: 260)
            } else {
                Image(systemName: "scribble")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColor.inkMuted.opacity(0.5))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(record.emotion.color.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: record.emotion.color.opacity(0.12), radius: 12, y: 4)
    }

    // MARK: - Duygu Başlığı

    private var emotionHeader: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: 7) {
                Text(record.emotion.emoji)
                    .font(.system(size: 18))
                Text(record.emotion.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(record.emotion.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(record.emotion.color.opacity(0.10))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(record.emotion.color.opacity(0.20), lineWidth: 1))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.date, style: .date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.ink)
                Text(record.date, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.inkMuted)
            }
        }
    }

    // MARK: - BPM Grafiği

    private var bpmChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Başlık
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppColor.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColor.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kalp Atışı Geçmişi")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                        Text("Çizim sırasındaki BPM değişimi")
                            .font(.system(size: 11))
                            .foregroundColor(AppColor.inkMuted)
                    }
                    Spacer()
                }

            // Mini istatistik kartları
            HStack(spacing: 12) {
                bpmStatChipView(label: "Ort.", valueStr: "\(avgBpm)", color: .blue)
                bpmStatChipView(label: "Min", valueStr: "\(minBpm)", color: .green)
                bpmStatChipView(label: "Maks", valueStr: "\(maxBpm)", color: .red)
                bpmStatChipView(label: "Süre", valueStr: durationText, color: .orange)
            }

            // Line Chart
            Chart {
                // Duygu zone bantları (arka plan)
                RectangleMark(
                    xStart: .value("", 0),
                    xEnd: .value("", maxSeconds),
                    yStart: .value("", 0),
                    yEnd: .value("", 70)
                )
                .foregroundStyle(Color.blue.opacity(0.06))

                RectangleMark(
                    xStart: .value("", 0),
                    xEnd: .value("", maxSeconds),
                    yStart: .value("", 70),
                    yEnd: .value("", 100)
                )
                .foregroundStyle(Color.orange.opacity(0.06))

                RectangleMark(
                    xStart: .value("", 0),
                    xEnd: .value("", maxSeconds),
                    yStart: .value("", 100),
                    yEnd: .value("", yAxisMax)
                )
                .foregroundStyle(Color.red.opacity(0.06))

                // Alan altı dolgusu
                ForEach(record.bpmHistory) { sample in
                    AreaMark(
                        x: .value("Süre", sample.secondsFromStart),
                        yStart: .value("", yAxisMin),
                        yEnd: .value("BPM", sample.bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [dominantColor.opacity(0.3), dominantColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Ana çizgi
                ForEach(record.bpmHistory) { sample in
                    LineMark(
                        x: .value("Süre", sample.secondsFromStart),
                        y: .value("BPM", sample.bpm)
                    )
                    .foregroundStyle(dominantColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }

                // Nokta işaretçiler
                ForEach(record.bpmHistory) { sample in
                    PointMark(
                        x: .value("Süre", sample.secondsFromStart),
                        y: .value("BPM", sample.bpm)
                    )
                    .foregroundStyle(dominantColor)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        Text("\(sample.bpm)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(dominantColor)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(formatSeconds(seconds))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let bpm = value.as(Int.self) {
                            Text("\(bpm)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisMin...yAxisMax)
            .frame(height: 200)

                // Zone açıklamaları
                HStack(spacing: 14) {
                    zoneLegend(color: .blue, label: "Sakin <70")
                    zoneLegend(color: .orange, label: "Enerjik 70-100")
                    zoneLegend(color: .red, label: "Stresli >100")
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - BPM Yok

    private var noBpmView: some View {
        AppCard {
            VStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColor.inkMuted.opacity(0.5))
                Text("BPM verisi yok")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("Yeni çizimler otomatik olarak BPM geçmişini kaydeder.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
        }
    }

    // MARK: - Yardımcı Bileşenler

    private func bpmStatChipView(label: String, valueStr: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(valueStr)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColor.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 0.8)
        )
    }

    private func zoneLegend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.5))
                .frame(width: 14, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColor.inkMuted)
        }
    }

    // MARK: - Hesaplanan Değerler

    private var avgBpm: Int {
        guard !record.bpmHistory.isEmpty else { return 0 }
        return record.bpmHistory.map(\.bpm).reduce(0, +) / record.bpmHistory.count
    }

    private var minBpm: Int {
        record.bpmHistory.map(\.bpm).min() ?? 0
    }

    private var maxBpm: Int {
        record.bpmHistory.map(\.bpm).max() ?? 0
    }

    private var maxSeconds: Double {
        record.bpmHistory.map(\.secondsFromStart).max() ?? 60
    }

    private var yAxisMin: Int {
        max(40, (minBpm - 15) / 10 * 10)
    }

    private var yAxisMax: Int {
        max(120, (maxBpm + 15) / 10 * 10)
    }

    private var dominantColor: Color {
        record.emotion.color
    }

    private var durationText: String {
        let total = Int(maxSeconds)
        if total < 60 { return "\(total)s" }
        return "\(total / 60)d"
    }

    private func formatSeconds(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins == 0 { return "\(secs)s" }
        return "\(mins)d\(secs > 0 ? "\(secs)s" : "")"
    }
}
