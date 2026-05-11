import SwiftUI

/// Vibe uygulama ikonunu temsil eden view.
/// Xcode'da AppIcon assets oluşturmak için önizleme olarak kullan.
struct AppIconView: View {
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Arka plan — koyu mor degrade
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.18, blue: 0.90),  // canlı mor
                    Color(red: 0.10, green: 0.05, blue: 0.35)   // derin lacivert
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Dalga efekti (duygu dalgası)
            WaveShape(amplitude: size * 0.07, frequency: 2.2, phase: 0)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.25), .clear],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: size * 0.018, lineCap: .round)
                )
                .offset(y: -size * 0.04)

            WaveShape(amplitude: size * 0.05, frequency: 2.8, phase: .pi * 0.4)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.15), .clear],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round)
                )
                .offset(y: size * 0.05)

            // Merkez — kalem + kalp
            VStack(spacing: size * 0.04) {
                ZStack {
                    // Parlak halka
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: size * 0.52, height: size * 0.52)

                    // İkon
                    Image(systemName: "scribble")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.30, height: size * 0.30)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.85, green: 0.70, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.6), radius: size * 0.04)
                }

                // Uygulama adı
                Text("vibe")
                    .font(.system(size: size * 0.115, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.85, green: 0.70, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .tracking(size * 0.008)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }
}

// MARK: - Dalga Şekli

private struct WaveShape: Shape {
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let angle = (x / rect.width) * frequency * .pi * 2 + phase
            let y = midY + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

// MARK: - Önizleme

#Preview("App Icon 1024") {
    AppIconView(size: 300)
        .padding(20)
        .background(Color.black)
}
