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
                // Header scuro
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                    Text("Segnala un numero")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Aiuta la community a proteggersi")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(darkBg)
                
                // Form su sfondo chiaro
                VStack(spacing: 18) {
                    // Numero
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NUMERO DI TELEFONO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("+39 333 1234567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .font(.system(size: 17))
                            .padding(13)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(phoneNumber.isEmpty ? Color(.systemGray3) :
                                            APIService.isValidPhoneNumber(phoneNumber) ? Color.green.opacity(0.5) : Color.orange.opacity(0.5),
                                            lineWidth: 1.5)
                            )
                        
                        if !phoneNumber.isEmpty && !APIService.isValidPhoneNumber(phoneNumber) {
                            Label("Usa solo cifre, es: 3331234567", systemImage: "exclamationmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Tipo
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIPO DI SEGNALAZIONE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Picker("Tipo", selection: $reportType) {
                            ForEach(reportTypes, id: \.0) { type in
                                Text(type.1).tag(type.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                    }
                    
                    // Categoria
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORIA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        Picker("Categoria", selection: $category) {
                            ForEach(categories, id: \.0) { cat in
                                Text(cat.1).tag(cat.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(13)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE (OPZIONALE)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("Es: Voce registrata, offerta gas...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.system(size: 16))
                            .padding(13)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray3), lineWidth: 1)
                            )
                    }
                    
                    // Bottone invio
                    Button(action: submitReport) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Invia segnalazione")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(canSubmit ? Color.red : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(!canSubmit || isLoading)
                    
                    // Messaggi
                    if let success = successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(success)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(14)
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
                    if response.message.contains("già segnalato") {
                        successMessage = "Hai già segnalato questo numero oggi. Grazie!"
                    } else {
                        successMessage = "Score: \(response.new_spam_score)/100 (\(response.total_reports) segnalazioni)"
                    }
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

