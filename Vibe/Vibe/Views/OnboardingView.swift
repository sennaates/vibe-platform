import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onFinish: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: nil,
            assetImage: "Logo",
            title: "Vibe'a Hoş Geldin",
            description: "Duygularının seni yönlendirdiği bir çizim deneyimi. Her çizgi, o anki hissinin bir yansıması.",
            color: AppColor.accent
        ),
        OnboardingPage(
            icon: "heart.fill", assetImage: nil,
            title: "Duygunu Ölç",
            description: "Apple Watch veya iPhone üzerinden kalp atışını okuyarak duygunu otomatik algılar. İstersen bilimsel test veya manuel ayarı kullanabilirsin.",
            color: Color(red: 0.85, green: 0.40, blue: 0.40)
        ),
        OnboardingPage(
            icon: "paintbrush.fill", assetImage: nil,
            title: "Duyguya Göre Çiz",
            description: "Sakinsen yumuşak marker, enerjiksen canlı kalem, stresli hissediyorsan keskin çizgiler ve koyu palet.",
            color: Color(red: 0.95, green: 0.65, blue: 0.30)
        ),
        OnboardingPage(
            icon: "photo.stack.fill", assetImage: nil,
            title: "Anılarını Sakla",
            description: "Her çizim duygu durumuyla galerine kaydedilir. Geçmiş çizimlerini incele, BPM grafiklerini gör.",
            color: Color(red: 0.55, green: 0.45, blue: 0.85)
        ),
    ]

    var body: some View {
        ZStack {
            // Sıcak arka plan
            AppColor.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                // Atla butonu
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            HapticManager.impact(.light)
                            onFinish()
                        } label: {
                            Text("Atla")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                    }
                }
                .frame(height: 30)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)

                // Sayfalar
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Alt kısım
                VStack(spacing: AppSpacing.lg) {
                    // Nokta göstergesi
                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage
                                      ? pages[currentPage].color
                                      : AppColor.divider)
                                .frame(width: i == currentPage ? 22 : 6, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    PrimaryButton(
                        title: currentPage == pages.count - 1 ? "Başla" : "Devam",
                        icon: currentPage == pages.count - 1 ? "sparkles" : "arrow.right",
                        color: pages[currentPage].color
                    ) {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onFinish()
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Logo veya ikon
            if let asset = page.assetImage {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 200)
                    .shadow(color: page.color.opacity(0.25), radius: 24, y: 8)
            } else if let icon = page.icon {
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.10))
                        .frame(width: 180, height: 180)
                    Circle()
                        .strokeBorder(page.color.opacity(0.20), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    Image(systemName: icon)
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(page.color)
                }
                .shadow(color: page.color.opacity(0.20), radius: 24, y: 8)
            }

            VStack(spacing: AppSpacing.md) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(AppColor.ink)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 15))
                    .foregroundColor(AppColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppSpacing.xl)
            }

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String?
    let assetImage: String?
    let title: String
    let description: String
    let color: Color
}
