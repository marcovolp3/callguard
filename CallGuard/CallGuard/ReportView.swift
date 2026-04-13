import SwiftUI

struct ReportView: View {
    @Binding var prefillNumber: String
    @State private var phoneNumber = ""
    @State private var reportType = "spam"
    @State private var category = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    let darkBg = Color(red: 0.08, green: 0.11, blue: 0.14)
    
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
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    Text("Segnala un numero")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Aiuta la community a proteggersi")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(darkBg)
                
                // Form
                VStack(spacing: 16) {
                    // Phone
                    FormField(label: "Numero di telefono") {
                        TextField("+39 333 1234567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    if !phoneNumber.isEmpty && !APIService.isValidPhoneNumber(phoneNumber) {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("Usa solo cifre, es: 3331234567")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 4)
                    }
                    
                    // Type
                    FormField(label: "Tipo di segnalazione") {
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
                    
                    // Category
                    FormField(label: "Categoria") {
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
                    
                    // Notes
                    FormField(label: "Note (opzionale)") {
                        TextField("Es: Voce registrata, offerta gas...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Submit
                    Button(action: submitReport) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Invia segnalazione")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(canSubmit ? Color.red : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!canSubmit || isLoading)
                    
                    // Messages
                    if let success = successMessage {
                        HStack(spacing: 8) {
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
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                            Text(error)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onChange(of: prefillNumber) { newValue in
            if !newValue.isEmpty {
                phoneNumber = newValue
                prefillNumber = ""
            }
        }
    }
    
    var canSubmit: Bool {
        !phoneNumber.isEmpty && APIService.isValidPhoneNumber(phoneNumber)
    }
    
    private func submitReport() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        guard canSubmit else { return }
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

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content()
        }
    }
}

