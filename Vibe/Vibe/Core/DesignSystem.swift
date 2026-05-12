import SwiftUI

// MARK: - Renk Paleti (Claude Tarzı: sıcak, doğal tonlar)

enum AppColor {
    /// Ana arka plan — sıcak kırık beyaz
    static var canvas: Color {
        Color(light: Color(red: 0.99, green: 0.98, blue: 0.96),
              dark:  Color(red: 0.10, green: 0.09, blue: 0.08))
    }

    /// Kart arka planı — ana yüzeyden hafif farklı
    static var surface: Color {
        Color(light: Color(red: 0.97, green: 0.96, blue: 0.93),
              dark:  Color(red: 0.14, green: 0.13, blue: 0.12))
    }

    /// İkincil yüzey
    static var surfaceMuted: Color {
        Color(light: Color(red: 0.94, green: 0.92, blue: 0.88),
              dark:  Color(red: 0.18, green: 0.17, blue: 0.15))
    }

    /// Ayraç çizgisi
    static var divider: Color {
        Color(light: Color(red: 0.88, green: 0.85, blue: 0.80),
              dark:  Color(red: 0.25, green: 0.23, blue: 0.20))
    }

    /// Birincil aksan — Claude turuncu
    static var accent: Color {
        Color(red: 0.85, green: 0.45, blue: 0.25)
    }

    /// İkincil aksan
    static var accentMuted: Color {
        Color(red: 0.90, green: 0.55, blue: 0.30)
    }

    /// Birincil metin
    static var ink: Color {
        Color(light: Color(red: 0.18, green: 0.16, blue: 0.14),
              dark:  Color(red: 0.95, green: 0.94, blue: 0.91))
    }

    /// İkincil metin
    static var inkMuted: Color {
        Color(light: Color(red: 0.45, green: 0.42, blue: 0.38),
              dark:  Color(red: 0.65, green: 0.62, blue: 0.58))
    }

    /// Üçüncül / soluk metin
    static var inkSubtle: Color {
        Color(light: Color(red: 0.65, green: 0.62, blue: 0.57),
              dark:  Color(red: 0.45, green: 0.43, blue: 0.40))
    }
}

// MARK: - Köşe yarıçapları

enum AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 22
}

// MARK: - Aralık değerleri

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
}

// MARK: - Color uzantısı: light/dark renk + hex

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    /// `"#D9723F"` veya `"D9723F"` formatında hex string'den Color oluşturur
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Yeniden Kullanılabilir Bileşenler

/// Standart bölüm başlığı (başlık + açıklama)
struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 19, weight: .semibold, design: .default))
                .foregroundColor(AppColor.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppColor.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Etiket (form alanı için, küçük ve sade)
struct FieldLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppColor.inkMuted)
            .textCase(.none)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Kart container — sıcak yüzey, hafif gölge
struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.lg

    init(padding: CGFloat = AppSpacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 0.5)
            )
    }
}

/// Birincil aksiyon butonu (Claude turuncu)
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var color: Color = AppColor.accent
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.medium)
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .shadow(color: color.opacity(0.25), radius: 8, y: 3)
        }
        .disabled(isLoading)
    }
}

/// İkincil buton (sade)
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.impact(.light)
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(AppColor.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }
}

/// Boş durum görünümü
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (title: String, handler: () -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColor.accent.opacity(0.10))
                    .frame(width: 86, height: 86)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(AppColor.accent)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let action {
                Button(action: { HapticManager.impact(.medium); action.handler() }) {
                    Text(action.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(AppColor.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
