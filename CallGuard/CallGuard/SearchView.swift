import SwiftUI

struct SearchView: View {
    @State private var phoneNumber = ""
    @State private var result: LookupResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let darkBg = Color(red: 0.08, green: 0.11, blue: 0.14)
    let gold = Color(red: 0.77, green: 0.64, blue: 0.27)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header scuro con branding
                VStack(spacing: 8) {
                    Text("BrunoBlock")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(gold)
                    Text("Bruno, non passa nessuno")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        TextField("Cerca numero di telefono...", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.top, 12)
                    
                    Button(action: search) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(darkBg)
                            } else {
                                Image(systemName: "shield.checkered")
                                Text("Verifica numero")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(phoneNumber.isEmpty ? Color.white.opacity(0.2) : gold)
                        .foregroundColor(phoneNumber.isEmpty ? .white.opacity(0.5) : .black)
                        .cornerRadius(12)
                    }
                    .disabled(phoneNumber.isEmpty || isLoading)
                }
                .padding(20)
                .padding(.top, 8)
                .background(darkBg)
                
                // Risultati
                VStack(spacing: 16) {
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text(error)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    if let result = result {
                        ResultCard(result: result)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func search() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        guard !phoneNumber.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        result = nil
        
        Task {
            do {
                let lookupResult = try await APIService.shared.lookup(number: phoneNumber)
                await MainActor.run {
                    result = lookupResult
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossibile contattare il server"
                    isLoading = false
                }
            }
        }
    }
}

struct ResultCard: View {
    let result: LookupResult
    
    var scoreColor: Color {
        if result.spam_score >= 70 { return .red }
        if result.spam_score >= 40 { return .orange }
        if result.spam_score > 0 { return .green }
        return .gray
    }
    
    var riskLabel: String {
        if !result.found { return "Sconosciuto" }
        if result.spam_score >= 85 { return "Molto pericoloso" }
        if result.spam_score >= 70 { return "Alto rischio" }
        if result.spam_score >= 40 { return "Rischio medio" }
        return "Rischio basso"
    }
    
    var riskIcon: String {
        if !result.found { return "questionmark.circle.fill" }
        if result.spam_score >= 70 { return "xmark.shield.fill" }
        if result.spam_score >= 40 { return "exclamationmark.triangle.fill" }
        return "checkmark.shield.fill"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Score header
            VStack(spacing: 10) {
                Text(result.number)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(result.found ? "\(result.spam_score)" : "?")
                    .font(.system(size: 64, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(result.found ? "spam score su 100" : "nessuno score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 6) {
                    Image(systemName: riskIcon)
                        .font(.system(size: 14))
                    Text(riskLabel)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [scoreColor, scoreColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Details
            if result.found {
                VStack(spacing: 0) {
                    DetailRow(label: "Categoria", value: formatCategory(result.category))
                    DetailRow(label: "Segnalazioni totali", value: "\(result.total_reports)")
                    if let recent = result.recent_reports_24h {
                        DetailRow(label: "Segnalazioni oggi", value: "\(recent)")
                    }
                    DetailRow(label: "Operatore", value: result.operator_name ?? "Sconosciuto")
                    DetailRow(label: "Azione consigliata", value: actionText, valueColor: actionColor, isLast: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            } else if let prefixRisk = result.prefix_risk, prefixRisk > 30 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(result.prefix_info ?? "Prefisso a rischio")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                .padding(16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: scoreColor.opacity(0.2), radius: 12, y: 4)
    }
    
    func formatCategory(_ category: String?) -> String {
        guard let cat = category else { return "—" }
        let labels: [String: String] = [
            "telemarketing_energia": "Energia (luce/gas)",
            "telemarketing_telefonia": "Telefonia",
            "telemarketing_assicurazioni": "Assicurazioni",
            "telemarketing": "Telemarketing",
            "truffa": "Truffa",
            "sondaggio": "Sondaggio",
        ]
        return labels[cat] ?? cat
    }
    
    var actionText: String {
        switch result.action_suggested {
        case "block": return "🚫 Blocca"
        case "warn": return "⚠️ Attenzione"
        default: return "✅ Sicuro"
        }
    }
    
    var actionColor: Color {
        switch result.action_suggested {
        case "block": return .red
        case "warn": return .orange
        default: return .green
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isLast: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
            }
        }
    }
}

