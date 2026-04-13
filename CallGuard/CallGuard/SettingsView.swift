import SwiftUI
import CallKit

struct SettingsView: View {
    @State private var lastSync: String = "Mai"
    @State private var syncedNumbers: Int = 0
    @State private var isSyncing = false
    @AppStorage("block_threshold") private var blockThreshold: Double = 90
    
    let darkBg = Color(red: 0.08, green: 0.11, blue: 0.14)
    let gold = Color(red: 0.77, green: 0.64, blue: 0.27)
    
    var blockDescription: String {
        if blockThreshold >= 95 {
            return "Solo spam verificato — massima cautela"
        } else if blockThreshold >= 85 {
            return "Alto rischio — blocca i numeri più segnalati"
        } else if blockThreshold >= 70 {
            return "Rischio medio-alto — protezione bilanciata"
        } else {
            return "Aggressivo — blocca anche numeri con poche segnalazioni"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 28))
                        .foregroundColor(gold)
                    Text("Impostazioni")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(darkBg)
                
                VStack(spacing: 16) {
                    
                    // Protezione chiamate
                    SectionCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Protezione chiamate", systemImage: "phone.badge.checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Text("Per identificare le chiamate spam, attiva BrunoBlock nelle impostazioni di iOS:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                StepRow(number: "1", text: "Apri Impostazioni iPhone")
                                StepRow(number: "2", text: "Vai su Telefono")
                                StepRow(number: "3", text: "Blocco chiamate e identificazione")
                                StepRow(number: "4", text: "Attiva BrunoBlock")
                            }
                            
                            Text("iOS non permette di aprire direttamente questa schermata. Segui i passaggi qui sopra manualmente.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    // Blocco automatico
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Blocco automatico", systemImage: "hand.raised.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                            
                            HStack {
                                Text("Soglia di blocco")
                                    .font(.system(size: 14))
                                Spacer()
                                Text("\(Int(blockThreshold))%")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.red)
                            }
                            
                            Slider(value: $blockThreshold, in: 50...100, step: 5)
                                .tint(.red)
                            
                            Text(blockDescription)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Text("Score < 50%: nessun avviso")
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                HStack(spacing: 8) {
                                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                                    Text("Score 50–\(Int(blockThreshold))%: etichetta, il telefono squilla")
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                HStack(spacing: 8) {
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                    Text("Score ≥ \(Int(blockThreshold))%: bloccato automaticamente")
                                        .font(.system(size: 12)).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Sincronizzazione
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Database locale", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                            
                            HStack {
                                Text("Numeri sincronizzati")
                                    .font(.system(size: 14))
                                Spacer()
                                Text("\(syncedNumbers)")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Ultimo aggiornamento")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(lastSync)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: syncNow) {
                                HStack {
                                    if isSyncing {
                                        ProgressView().tint(.blue)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(isSyncing ? "Sincronizzazione..." : "Sincronizza ora")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray5))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            .disabled(isSyncing)
                        }
                    }
                    
                    // Info
                    SectionCard {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Versione").font(.system(size: 14))
                                Spacer()
                                Text("2.0.0").font(.system(size: 14)).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack {
                                Text("Backend").font(.system(size: 14))
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Text("Online").font(.system(size: 14)).foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
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

struct SectionCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
    }
}

struct StepRow: View {
    let number: String
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.blue)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 14))
        }
    }
}
