import SwiftUI
import CallKit

struct SettingsView: View {
    @State private var callKitEnabled = false
    @State private var lastSync: String = "Mai"
    @State private var syncedNumbers: Int = 0
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "phone.badge.checkmark")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Identificazione chiamate")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Mostra avvisi spam durante le chiamate in arrivo")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Come attivare:")
                            .font(.system(size: 14, weight: .semibold))
                        
                        StepRow(number: "1", text: "Apri Impostazioni dell'iPhone")
                        StepRow(number: "2", text: "Vai su Telefono")
                        StepRow(number: "3", text: "Tocca Blocco chiamate e identificazione")
                        StepRow(number: "4", text: "Attiva CallGuard")
                    }
                    .padding(.vertical, 8)
                    
                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Apri Impostazioni")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Protezione chiamate")
                }
                
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Numeri sincronizzati")
                                .font(.system(size: 14))
                            Text("\(syncedNumbers) numeri spam nel database locale")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(syncedNumbers)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Ultimo aggiornamento")
                            .font(.system(size: 14))
                        Spacer()
                        Text(lastSync)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: syncNow) {
                        HStack {
                            if isSyncing {
                                ProgressView()
                                    .tint(.blue)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(isSyncing ? "Sincronizzazione..." : "Sincronizza ora")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSyncing)
                } header: {
                    Text("Database locale")
                }
                
                Section {
                    HStack {
                        Text("Versione")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Backend")
                        Spacer()
                        Text("Online")
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func syncNow() {
        isSyncing = true
        Task {
            do {
                let numbers = try await APIService.shared.syncNumbers()
                await MainActor.run {
                    syncedNumbers = numbers.count
                    reloadCallDirectory()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm, d MMM"
                    formatter.locale = Locale(identifier: "it_IT")
                    lastSync = formatter.string(from: Date())
                    isSyncing = false
                }
            } catch {
                await MainActor.run {
                    isSyncing = false
                }
            }
        }
    }
    
    private func reloadCallDirectory() {
        CXCallDirectoryManager.sharedInstance.reloadExtension(
            withIdentifier: "com.marcovolp3.CallGuard.CallGuardExtension"
        ) { error in
            if let error = error {
                print("Errore reload CallDirectory: \(error)")
            } else {
                print("CallDirectory aggiornata con successo")
            }
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 14))
        }
    }
}
