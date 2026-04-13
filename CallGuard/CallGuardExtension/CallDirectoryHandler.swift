import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        let numbers = loadSpamNumbers()
        print("CallDirectory: caricati \(numbers.count) numeri")

        for entry in numbers {
            print("CallDirectory: aggiunto \(entry.phoneNumber) - \(entry.label)")
            context.addIdentificationEntry(withNextSequentialPhoneNumber: entry.phoneNumber, label: entry.label)
        }

        context.completeRequest()
    }

    private func loadSpamNumbers() -> [(phoneNumber: CXCallDirectoryPhoneNumber, label: String)] {
        var entries: [(CXCallDirectoryPhoneNumber, String)] = []

        guard let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.marcovolp3.CallGuard"
        ) else {
            print("CallDirectory: ERRORE - App Group non trovato")
            return entries
        }

        let fileURL = sharedURL.appendingPathComponent("spam_numbers.json")
        
        print("CallDirectory: cerco file in \(fileURL.path)")

        guard let data = try? Data(contentsOf: fileURL) else {
            print("CallDirectory: ERRORE - file non trovato")
            return entries
        }
        
        guard let numbers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("CallDirectory: ERRORE - JSON non valido")
            return entries
        }

        print("CallDirectory: trovati \(numbers.count) numeri nel file JSON")

        let sorted = numbers.sorted {
            ($0["number"] as? Int64 ?? 0) < ($1["number"] as? Int64 ?? 0)
        }

        for item in sorted {
            if let number = item["number"] as? Int64,
               let label = item["label"] as? String {
                entries.append((CXCallDirectoryPhoneNumber(number), label))
            }
        }
        
        print("CallDirectory: \(entries.count) numeri convertiti con successo")

        return entries
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("CallDirectory ERRORE: \(error.localizedDescription)")
    }
}
