//
//  VibeApp.swift
//  Vibe
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UserNotifications

// MARK: - Push Notifications delegate
// FirebaseMessaging bağımlılığı Xcode'dan eklenmelidir:
//   File > Add Package Dependencies > https://github.com/firebase/firebase-ios-sdk
//   → FirebaseMessaging seçin
// Ardından aşağıdaki yorumlu import ve UNUserNotificationCenterDelegate kodunu aktif edin.

// import FirebaseMessaging

@main
struct VibeApp: App {
    @StateObject private var authService = AuthService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        FirebaseConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission(application)
        return true
    }

    // MARK: İzin İsteği

    private func requestNotificationPermission(_ application: UIApplication) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
    }

    // MARK: APNs token alındı — Firestore'a yaz

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // FirebaseMessaging kurulduktan sonra bu satırı etkinleştir:
        // Messaging.messaging().apnsToken = deviceToken

        // Token'ı raw hex olarak Firestore'a kaydet (geçici, FCM kurulana kadar)
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        storePushToken(tokenString, type: "apns")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ APNs token alınamadı:", error.localizedDescription)
    }

    // MARK: Bildirim geldiğinde (uygulama açıkken)

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Bildirime tıklama — ilgili içeriğe yönlendir
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: .vibePushTapped,
            object: nil,
            userInfo: userInfo
        )
        completionHandler()
    }

    // MARK: Firestore'a token kaydet

    private func storePushToken(_ token: String, type: String) {
        guard let uid = AuthService.shared.firebaseUser?.uid else { return }
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData(["pushToken": token, "pushTokenType": type]) { err in
                if let err { print("⚠️ pushToken kaydedilemedi:", err) }
            }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let vibePushTapped = Notification.Name("vibePushTapped")
}
