//
//  FirebaseConfig.swift
//  Vibe
//
//  Created by Sena Ateş on 02.05.2026.
//

import Foundation
import FirebaseCore

/// Firebase yapılandırmasını .env dosyasından API key okuyarak gerçekleştirir.
/// Eğer .env bulunamazsa, plist'teki mevcut değeri kullanır (fallback).
enum FirebaseConfig {
    
    /// Firebase'i yapılandırır. AppDelegate veya @main init() içinde çağrılmalıdır.
    static func configure() {
        // GoogleService-Info.plist'ten varsayılan options'ı al
        guard var options = FirebaseOptions.defaultOptions() else {
            fatalError("GoogleService-Info.plist bulunamadı veya okunamadı.")
        }
        
        // .env dosyasından API key'i oku
        if let apiKey = Self.loadAPIKeyFromEnv() {
            options.apiKey = apiKey
        }
        
        FirebaseApp.configure(options: options)
    }
    
    /// .env dosyasından FIREBASE_API_KEY değerini okur.
    /// .env dosyası Bundle (app) içinde değil, proje kök dizininde yer alır.
    /// Build sırasında xcconfig veya script ile inject edilebilir;
    /// burada runtime'da plist üzerinden okuma yapıyoruz.
    private static func loadAPIKeyFromEnv() -> String? {
        // Önce Bundle içindeki .env dosyasını kontrol et (Copy Bundle Resources ile eklenirse)
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            return parseEnvFile(at: envPath)
        }
        
        // Geliştirme ortamında: SRCROOT/.env dosyasını bul
        // Bu sadece DEBUG modda çalışır
        #if DEBUG
        // Proje dizininde .env dosyasını aramak için __FILE__ trick'i
        let sourceFile = #file
        if let sourceDir = URL(string: sourceFile)?.deletingLastPathComponent().deletingLastPathComponent() {
            let envURL = sourceDir.appendingPathComponent(".env")
            let envPath = envURL.path
            if FileManager.default.fileExists(atPath: envPath) {
                return parseEnvFile(at: envPath)
            }
        }
        
        // Fallback: proje yapısı üzerinden tahmin
        if let projectDir = ProcessInfo.processInfo.environment["SRCROOT"] {
            let envPath = "\(projectDir)/.env"
            if FileManager.default.fileExists(atPath: envPath) {
                return parseEnvFile(at: envPath)
            }
        }
        #endif
        
        return nil
    }
    
    /// .env dosyasını parse eder ve FIREBASE_API_KEY değerini döndürür.
    private static func parseEnvFile(at path: String) -> String? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Yorum satırlarını atla
            if trimmed.hasPrefix("#") || trimmed.isEmpty { continue }
            
            let parts = trimmed.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                
                if key == "FIREBASE_API_KEY" {
                    return value
                }
            }
        }
        
        return nil
    }
}
