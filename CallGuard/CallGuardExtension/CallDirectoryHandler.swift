import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // Carica i numeri spam salvati localmente
        let numbers = loadSpamNumbers()

        for entry in numbers {
            let phoneNumber = entry.phoneNumber
            let label = entry.label
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }

        context.completeRequest()
    }

    private func loadSpamNumbers() -> [(phoneNumber: CXCallDirectoryPhoneNumber, label: String)] {
        var entries: [(CXCallDirectoryPhoneNumber, String)] = []

        // Leggi dal file condiviso con l'app principale
        guard let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.marcovolp3.CallGuard"
        ) else {
            return entries
        }

        let fileURL = sharedURL.appendingPathComponent("spam_numbers.json")

        guard let data = try? Data(contentsOf: fileURL),
              let numbers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return entries
        }

        // I numeri DEVONO essere in ordine crescente per CallKit
        let sorted = numbers.sorted {
            ($0["number"] as? Int64 ?? 0) < ($1["number"] as? Int64 ?? 0)
        }

        for item in sorted {
            if let number = item["number"] as? Int64,
               let label = item["label"] as? String {
                entries.append((CXCallDirectoryPhoneNumber(number), label))
            }
        }

        return entries
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("CallDirectory errore: \(error.localizedDescription)")
    }
}
