# Vibe — Duyguyla Çiz

Kalp atışınla şekillenen bir çizim ve paylaşım platformu.  
iOS native uygulaması + Next.js web uygulamasından oluşan full-stack proje.

---

## Özellikler

### Çizim
- Kalp atış hızı (BPM) fırça parametrelerini otomatik ayarlar (boyut, opaklık, renk paleti, efekt)
- 10 duygu modu: Sakin, Mutlu, Enerjik, Heyecanlı, Kaygılı, Stresli, Üzgün, Yorgun, Huzurlu, Odaklanmış
- Boş / Kareli / Çizgili arka plan seçenekleri
- iOS native canvas (PencilKit tabanlı) · Web HTML5 Canvas

### Sosyal
- Gönderi paylaşma, beğenme, yorum yapma
- **Yorum yanıtlama** — `@kullanıcı` referansıyla nested replies
- Takip / takipten çıkma · Keşfet ve Takip feed'i
- **Hashtag sistemi** — caption'daki `#etiket`ler tıklanabilir, hashtag sayfası
- İçerik şikayeti (report) · Gönderi silme
- Bildirimler: beğeni, yorum, takip · Okundu işareti

### Profil & Ayarlar
- Emoji avatar + renk seçimi · Bio düzenleme
- Caption sonradan düzenlenebilir (tags[] otomatik güncellenir)
- İstatistik sayfası: aktivite haritası, BPM grafiği, duygu dağılımı, haftalık alışkanlık, top hashtagler
- Bildirim tercihleri (beğeni / yorum / takip) · Gizli hesap modu

### Web (PWA)
- Dark mode (sistem teması veya manuel)
- Offline desteği (Service Worker + offline.html)
- SEO & Open Graph meta — post ve profil sayfaları için dinamik
- Sonsuz scroll (Keşfet, Takip, Hashtag feed'leri)
- Trend hashtagler sidebar widget'ı

---

## Proje Yapısı

```
vibe/
├── Vibe/                        # iOS (Swift / SwiftUI)
│   └── Vibe/
│       ├── Models/              # DrawingRecord, EmotionState, SocialModels, UserProfile
│       ├── Services/            # AuthService, BiometricService, FeedService, SocialService
│       ├── Core/                # DrawingEngine, EmotionClassifier, HapticManager, DesignSystem, FirebaseConfig
│       ├── Stores/              # DrawingStore, GalleryStore, UserStore (ObservableObject)
│       └── Views/
│           ├── Auth/            # AuthView, OnboardingView, UserFormView
│           ├── Canvas/          # CanvasView, DrawingDetailView, GalleryView, MoodInputView…
│           ├── Feed/            # FeedView, PostCard, PostDetailView, HashtagFeedView, SharePostView
│           ├── Profile/         # EditProfileView, PublicProfileView, SettingsView
│           ├── Discover/        # SearchView
│           ├── Activity/        # NotificationsView, StatsView
│           └── Shared/          # CaptionText, UserListView
│
├── vibe-web/                    # Web (Next.js 15 App Router + Tailwind v4)
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx             # Ana feed (Keşfet / Takip)
│   │   │   ├── canvas/              # Çizim sayfası
│   │   │   ├── post/[id]/           # Gönderi detay + OG meta
│   │   │   ├── profile/[uid]/       # Profil + OG meta
│   │   │   ├── hashtag/[tag]/       # Hashtag feed
│   │   │   ├── search/              # Kullanıcı / hashtag arama
│   │   │   ├── notifications/
│   │   │   ├── stats/               # İstatistik dashboard
│   │   │   └── settings/
│   │   ├── components/
│   │   │   ├── feed/        # Feed, FollowingFeed, PostCard
│   │   │   ├── canvas/      # DrawingCanvas, EmotionPicker
│   │   │   ├── discover/    # TrendingEmotions, TrendingHashtags, SuggestedUsers
│   │   │   ├── profile/     # FollowListModal
│   │   │   ├── layout/      # Navbar
│   │   │   └── ui/          # Avatar, Button, Caption, Card, Toast, ThemeProvider…
│   │   ├── hooks/           # useAuth
│   │   ├── lib/             # firebase, firestore-rest, drawingEngine, notifications, toast, utils
│   │   └── types/           # index.ts
│   └── public/
│       ├── sw.js            # Service Worker (network-first)
│       └── offline.html
│
├── firestore.rules          # Güvenlik kuralları
├── firestore.indexes.json   # Composite index tanımları
└── firebase.json
```

---

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| iOS | Swift 5.9 · SwiftUI · Firebase iOS SDK |
| Web | Next.js 15 (App Router) · TypeScript · Tailwind CSS v4 |
| Veritabanı | Firebase Firestore |
| Kimlik | Firebase Authentication (email/şifre) |
| Medya | Cloudinary (görsel yükleme) |
| PWA | Service Worker · Web App Manifest |

---

## Kurulum

### Gereksinimler
- Node.js 20+
- Xcode 15+
- Firebase projesi
- Cloudinary hesabı

### Web

```bash
cd vibe-web
npm install
cp .env.local.example .env.local
# .env.local dosyasını doldur (Firebase + Cloudinary bilgileri)
npm run dev
```

### iOS

1. `Vibe/Vibe/GoogleService-Info.plist` dosyasına Firebase yapılandırmanı ekle
2. `FeedService.swift` içindeki `cloudinaryCloudName` ve `cloudinaryUploadPreset` değerlerini güncelle
3. Xcode'da çalıştır

### Firestore Kuralları & İndeksler

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore
```

---

## Ortam Değişkenleri (Web)

`.env.local.example` dosyasını kopyala ve doldur:

```env
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=
```

---

## Firestore Koleksiyonları

| Koleksiyon | Açıklama |
|------------|----------|
| `users/{uid}` | Kullanıcı profili |
| `posts/{postId}` | Gönderi (imageUrl, emotion, bpm, caption, tags[]) |
| `posts/{postId}/comments` | Yorumlar (replyToId, replyToName destekli) |
| `posts/{postId}/likes/{uid}` | Web beğeni kaydı |
| `likes/{uid}_{postId}` | iOS beğeni kaydı |
| `follows/{followerId}_{followedId}` | Takip ilişkisi |
| `userLikes/{uid}/items` | Web beğeni listesi (çift yazma) |
| `notifications/{uid}/items` | Kullanıcı bildirimleri |
| `reports/{reportId}` | İçerik şikayetleri |
