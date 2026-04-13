import Foundation

struct LookupResult: Codable {
    let found: Bool
    let number: String
    let spam_score: Int
    let category: String?
    let total_reports: Int
    let risk_level: String
    let operator_name: String?
    let action_suggested: String
    let recent_reports_24h: Int?
    let prefix_risk: Int?
    let prefix_info: String?
}

struct ReportResponse: Codable {
    let success: Bool
    let phone_number: String
    let new_spam_score: Int
    let total_reports: Int
    let message: String
}

struct FeedItem: Codable, Identifiable {
    var id: String { number_masked }
    let number_masked: String
    let number_full: String
    let spam_score: Int
    let total_reports: Int
    let category_label: String
    let operator_name: String?
    let trend: String
}

struct FeedResponse: Codable {
    let reports: [FeedItem]
}

struct StatsResponse: Codable {
    let total_numbers_tracked: Int
    let total_reports: Int
    let high_risk_numbers: Int
}

struct ReportRequest: Codable {
    let phone_number: String
    let report_type: String
    let category: String
    let description: String
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://callguard-production.up.railway.app"
    
    func lookup(number: String) async throws -> LookupResult {
        var cleanNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanNumber.hasPrefix("+") {
            cleanNumber = "+39" + cleanNumber
        }
        
        guard let encoded = cleanNumber.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/api/lookup/\(encoded)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LookupResult.self, from: data)
    }
    
    func report(phoneNumber: String, reportType: String, category: String, description: String) async throws -> ReportResponse {
        var cleanNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanNumber.hasPrefix("+") {
            cleanNumber = "+39" + cleanNumber
        }
        
        guard let url = URL(string: "\(baseURL)/api/report") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ReportRequest(
            phone_number: cleanNumber,
            report_type: reportType,
            category: category,
            description: description
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ReportResponse.self, from: data)
    }
    
    func feed(limit: Int = 20) async throws -> [FeedItem] {
        guard let url = URL(string: "\(baseURL)/api/feed?limit=\(limit)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(FeedResponse.self, from: data)
        return response.reports
    }
    
    func stats() async throws -> StatsResponse {
        guard let url = URL(string: "\(baseURL)/api/stats") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StatsResponse.self, from: data)
    }
    
    func syncNumbers(since: String = "2000-01-01") async throws -> [[String: Any]] {
        guard let url = URL(string: "\(baseURL)/api/sync/ios?since=\(since)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let numbers = json?["numbers"] as? [[String: Any]] ?? []
        
        saveToSharedContainer(numbers: numbers)
        
        return numbers
    }
    
    private func saveToSharedContainer(numbers: [[String: Any]]) {
        guard let sharedURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.marcovolp3.CallGuard"
        ) else { return }
        
        let fileURL = sharedURL.appendingPathComponent("spam_numbers.json")
        
        var callKitNumbers: [[String: Any]] = []
        
        for item in numbers {
            guard let numberStr = item["number"] as? String,
                  let label = item["label"] as? String else { continue }
            
            let cleaned = numberStr.replacingOccurrences(of: "+", with: "")
            if let numberInt = Int64(cleaned) {
                callKitNumbers.append([
                    "number": numberInt,
                    "label": label
                ])
            }
        }
        
        callKitNumbers.sort {
            ($0["number"] as? Int64 ?? 0) < ($1["number"] as? Int64 ?? 0)
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: callKitNumbers) {
            try? jsonData.write(to: fileURL)
        }
    }
}
