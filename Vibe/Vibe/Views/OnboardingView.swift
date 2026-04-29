import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onFinish: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🎨",
            title: "Vibe'a Hoş Geldin",
            description: "Duygularının seni yönlendirdiği bir çizim deneyimi. Her çizgi, o anki hissinin bir yansıması.",
            color: .blue
        ),
        OnboardingPage(
            emoji: "💓",
            title: "Duygunu Ölç",
            description: "Apple Watch veya iPhone üzerinden kalp atış hızını okuyarak duygunu otomatik algılar. İstersen psikolojik test veya manuel ayarı da kullanabilirsin.",
            color: .red
        ),
        OnboardingPage(
            emoji: "🖌️",
            title: "Duyguya Göre Çiz",
            description: "Sakinsen yumuşak marker ve pastel renkler. Enerjiksen dinamik kalem ve canlı tonlar. Stresli hissediyorsan keskin çizgiler ve koyu palet.",
            color: .orange
        ),
        OnboardingPage(
            emoji: "🖼️",
            title: "Anılarını Kaydet",
            description: "Her çizim, o anki duygu durumuyla birlikte galerine kaydedilir. Sakin anlarında mı, yoksa stresli anlarında mı daha güzel çiziyorsun?",
            color: .purple
        ),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { i in
                    pageView(pages[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 20) {
                // Nokta göstergesi
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? pages[currentPage].color : Color.secondary.opacity(0.3))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }

                // Buton
                Button {
                    HapticManager.impact(.medium)
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(currentPage == pages.count - 1 ? "Başla" : "Devam")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pages[currentPage].color)
                        .cornerRadius(14)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
        .ignoresSafeArea()
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 160, height: 160)
                Text(page.emoji)
                    .font(.system(size: 72))
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
    let color: Color
}
