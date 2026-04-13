import SwiftUI

struct ReportView: View {
    @State private var phoneNumber = ""
    @State private var reportType = "spam"
    @State private var category = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    let reportTypes = [
        ("spam", "Spam generico"),
        ("telemarketing", "Telemarketing"),
        ("truffa", "Truffa / Phishing"),
        ("sondaggio", "Sondaggio"),
        ("legittimo", "Numero legittimo (errore)")
    ]
    
    let categories = [
        ("", "— Seleziona —"),
        ("telemarketing_energia", "Energia (luce/gas)"),
        ("telemarketing_telefonia", "Telefonia / Internet"),
        ("telemarketing_assicurazioni", "Assicurazioni"),
        ("truffa", "Truffa / Frode"),
        ("sondaggio", "Sondaggio / Ricerca")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Numero di telefono")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("+39 333 1234567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tipo di segnalazione")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Picker("Tipo", selection: $reportType) {
                            ForEach(reportTypes, id: \.0) { type in
                                Text(type.1).tag(type.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categoria")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Picker("Categoria", selection: $category) {
                            ForEach(categories, id: \.0) { cat in
                                Text(cat.1).tag(cat.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note (opzionale)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("Es: Voce registrata, offerta gas...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    Button(action: submitReport) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "exclamationmark.bubble.fill")
                                Text("Invia segnalazione")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(phoneNumber.isEmpty ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(phoneNumber.isEmpty || isLoading)
                    
                    if let success = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(success)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Segnala")
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func submitReport() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        guard !phoneNumber.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let response = try await APIService.shared.report(
                    phoneNumber: phoneNumber,
                    reportType: reportType,
                    category: category,
                    description: description
                )
                await MainActor.run {
                    successMessage = "Score: \(response.new_spam_score)/100 (\(response.total_reports) segnalazioni)"
                    phoneNumber = ""
                    description = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Errore di connessione"
                    isLoading = false
                }
            }
        }
    }
}
