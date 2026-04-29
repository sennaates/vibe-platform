import Foundation
import HealthKit
import Combine

class BiometricService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var currentBPM: Int = 65
    @Published var isAuthorized: Bool = false
    @Published var isMocking: Bool = false
    @Published var currentEmotion: EmotionState = .calm

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            enableMockMode()
            return
        }

        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { [weak self] success, _ in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startHeartRateQuery()
                } else {
                    self?.enableMockMode()
                }
            }
        }
    }

    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, completionHandler, error in
            if error == nil {
                self?.fetchLatestHeartRate()
            }
            completionHandler()
        }

        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }
    }

    private func fetchLatestHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            let bpm = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
            DispatchQueue.main.async {
                self?.currentBPM = bpm
                self?.currentEmotion = EmotionClassifier.classify(bpm: bpm)
            }
        }

        healthStore.execute(query)
    }

    func enableMockMode() {
        self.isMocking = true
        self.currentBPM = 65
        self.currentEmotion = .calm
    }

    func setMockBPM(_ bpm: Int) {
        self.currentBPM = bpm
        self.currentEmotion = EmotionClassifier.classify(bpm: bpm)
    }
}
