import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        let numbers = loadSpamNumbers()
        let blockThreshold = getBlockThreshold()
        
        var identifyCount = 0
        var blockCount = 0

        // Prima: aggiungi tutti i numeri da BLOCCARE (score >= soglia)
        // I numeri bloccati DEVONO essere aggiunti prima di quelli identificati
        // e DEVONO essere in ordine crescente
        let toBlock = numbers.filter { $0.score >= blockThreshold }
        for entry in toBlock {
            context.addBlockingEntry(withNextSequentialPhoneNumber: entry.phoneNumber)
            blockCount += 1
        }
        
        // Poi: aggiungi tutti i numeri da IDENTIFICARE (tutti, inclusi quelli bloccati)
        for entry in numbers {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: entry.phoneNumber, label: entry.label)
            identifyCount += 1
        }

        print("CallDirectory: \(identifyCount) identificati, \(blockCount) bloccati (soglia: \(blockThreshold)%)")
        context.completeRequest()
    }

    private func getBlockThreshold() -> Int {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.marcovolp3.CallGuard") {
            let threshold = sharedDefaults.integer(forKey: "block_threshold")
            return threshold > 0 ? threshold : 90
        }
        return 90
    }

    private func loadSpamNumbers() -> [(phoneNumber: CXCallDirectoryPhoneNumber, label: String, score: Int)] {
        var entries: [(CXCallDirectoryPhoneNumber, String, Int)] = []

        guard let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.marcovolp3.CallGuard"
        ) else {
            print("CallDirectory: ERRORE - App Group non trovato")
            return entries
        }

        let fileURL = sharedURL.appendingPathComponent("spam_numbers.json")

        guard let data = try? Data(contentsOf: fileURL),
              let numbers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("CallDirectory: ERRORE - file non trovato o JSON non valido")
            return entries
        }

        let sorted = numbers.sorted {
            ($0["number"] as? Int64 ?? 0) < ($1["number"] as? Int64 ?? 0)
        }

        for item in sorted {
            if let number = item["number"] as? Int64,
               let label = item["label"] as? String {
                let score = item["score"] as? Int ?? 0
                entries.append((CXCallDirectoryPhoneNumber(number), label, score))
            }
        }

        return entries
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("CallDirectory ERRORE: \(error.localizedDescription)")
    }
}

