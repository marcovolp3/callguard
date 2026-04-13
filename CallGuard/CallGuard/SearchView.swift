import SwiftUI

struct SearchView: View {
    @State private var phoneNumber = ""
    @State private var result: LookupResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Numero di telefono...", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .font(.system(size: 17))
                        }
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        Button(action: search) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Cerca numero")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(phoneNumber.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(phoneNumber.isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if let result = result {
                        ResultCard(result: result)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 12)
            }
            .navigationTitle("BrunoBlock")
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
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
                    errorMessage = "Errore di connessione al server"
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
        if !result.found { return "questionmark.circle" }
        if result.spam_score >= 70 { return "xmark.shield.fill" }
        if result.spam_score >= 40 { return "exclamationmark.triangle.fill" }
        return "checkmark.shield.fill"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(result.number)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                
                Text(result.found ? "\(result.spam_score)" : "?")
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(scoreColor)
                
                Text(result.found ? "spam score su 100" : "nessuno score")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    Image(systemName: riskIcon)
                        .font(.system(size: 14))
                    Text(riskLabel)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(scoreColor.opacity(0.15))
                .foregroundColor(scoreColor)
                .cornerRadius(20)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(scoreColor.opacity(0.08))
            
            if result.found {
                VStack(spacing: 0) {
                    DetailRow(label: "Categoria", value: result.category ?? "—")
                    DetailRow(label: "Segnalazioni totali", value: "\(result.total_reports)")
                    if let recent = result.recent_reports_24h {
                        DetailRow(label: "Segnalazioni oggi", value: "\(recent)")
                    }
                    DetailRow(label: "Operatore", value: result.operator_name ?? "Sconosciuto")
                    DetailRow(label: "Azione consigliata", value: actionText, valueColor: actionColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else if let prefixRisk = result.prefix_risk, prefixRisk > 30 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(result.prefix_info ?? "Prefisso a rischio")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    var actionText: String {
        switch result.action_suggested {
        case "block": return "🚫 Blocca"
        case "warn": return "⚠️ Attenzione"
        default: return "✅ OK"
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
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 10)
        .overlay(
            Divider(), alignment: .bottom
        )
    }
}
