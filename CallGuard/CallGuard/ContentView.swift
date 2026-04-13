import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    @State private var clipboardNumber: String?
    @State private var showClipboardBanner = false
    @State private var prefillNumber: String = ""
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                SearchView()
                    .tabItem {
                        Label("Cerca", systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                ReportView(prefillNumber: $prefillNumber)
                    .tabItem {
                        Label("Segnala", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tag(1)
                
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet.rectangle")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Label("Impostazioni", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.blue)
            
            if showClipboardBanner, let number = clipboardNumber {
                VStack {
                    ClipboardBanner(number: number, onReport: {
                        UIPasteboard.general.string = ""
                        prefillNumber = number
                        selectedTab = 1
                        withAnimation { showClipboardBanner = false }
                    }, onDismiss: {
                        UIPasteboard.general.string = ""
                        withAnimation { showClipboardBanner = false }
                    })
                    .padding(.top, 50)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
            
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(200)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !showSplash {
                checkClipboard()
            }
        }
    }
    
    private func checkClipboard() {
        guard !showClipboardBanner else { return }
        
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings, let content = pasteboard.string else { return }
        
        let digitsOnly = content.filter { $0.isNumber }
        guard digitsOnly.count >= 8 && digitsOnly.count <= 15 else { return }
        
        let cleaned = APIService.cleanPhoneNumber(content)
        guard APIService.isValidPhoneNumber(cleaned) else { return }
        
        clipboardNumber = cleaned
        withAnimation(.spring(response: 0.4)) {
            showClipboardBanner = true
        }
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.11, blue: 0.14)
                .ignoresSafeArea()
            
            if UIImage(named: "splash_bruno") != nil {
                Image("splash_bruno")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Text("🛡️")
                        .font(.system(size: 80))
                    Text("BrunoBlock")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundColor(Color(red: 0.77, green: 0.64, blue: 0.27))
                    Text("Con Bruno\nnon passa nessuno")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(red: 0.77, green: 0.64, blue: 0.27).opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct ClipboardBanner: View {
    let number: String
    let onReport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Numero negli appunti")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(number)
                    .font(.system(size: 15, weight: .bold))
            }
            
            Spacer()
            
            Button(action: onReport) {
                Text("Segnala")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal, 16)
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let darkBg = Color(red: 0.08, green: 0.11, blue: 0.14)
    let gold = Color(red: 0.77, green: 0.64, blue: 0.27)
    
    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    VStack(spacing: 24) {
                        Spacer()
                        Text("🛡️").font(.system(size: 80))
                        Text("BrunoBlock")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(gold)
                        Text("Con Bruno, non passa nessuno.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Identifica e blocca le chiamate spam e i call center molesti.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }.tag(0)
                    
                    VStack(spacing: 24) {
                        Spacer()
                        Text("📞").font(.system(size: 80))
                        Text("Come funziona")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 18) {
                            OnboardingFeature(icon: "magnifyingglass", color: .blue, text: "Cerca un numero sospetto")
                            OnboardingFeature(icon: "exclamationmark.triangle.fill", color: .red, text: "Segnala chi ti disturba")
                            OnboardingFeature(icon: "phone.badge.checkmark", color: .green, text: "Bruno ti avvisa in tempo reale")
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    }.tag(1)
                    
                    VStack(spacing: 24) {
                        Spacer()
                        Text("⚙️").font(.system(size: 80))
                        Text("Attiva la protezione")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Per completare l'attivazione, vai nelle impostazioni di iOS:")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        VStack(alignment: .leading, spacing: 14) {
                            OnboardingStepRow(number: "1", text: "Apri Impostazioni iPhone")
                            OnboardingStepRow(number: "2", text: "Vai su Telefono")
                            OnboardingStepRow(number: "3", text: "Blocco chiamate e identificazione")
                            OnboardingStepRow(number: "4", text: "Attiva BrunoBlock")
                        }
                        .padding(.horizontal, 40)
                        Text("iOS non permette di aprire questa schermata direttamente. Segui i passaggi qui sopra.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                Button(action: {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: "onboarding_completed")
                        isPresented = false
                    }
                }) {
                    Text(currentPage < 2 ? "Avanti" : "Inizia a usare Bruno")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(gold)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingFeature: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct OnboardingStepRow: View {
    let number: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 26, height: 26)
                .background(Color(red: 0.77, green: 0.64, blue: 0.27))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
