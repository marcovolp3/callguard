import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    @State private var clipboardNumber: String?
    @State private var showClipboardBanner = false
    @State private var prefillNumber: String = ""
    
    var body: some View {
        ZStack {
            // Main app
            TabView(selection: $selectedTab) {
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Cerca")
                    }
                    .tag(0)
                
                ReportView(prefillNumber: $prefillNumber)
                    .tabItem {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Segnala")
                    }
                    .tag(1)
                
                FeedView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Feed")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Impostazioni")
                    }
                    .tag(3)
            }
            .tint(Color("AccentGold"))
            
            // Clipboard banner
            if showClipboardBanner, let number = clipboardNumber {
                VStack {
                    ClipboardBanner(number: number, onReport: {
                        prefillNumber = number
                        selectedTab = 1
                        showClipboardBanner = false
                    }, onDismiss: {
                        showClipboardBanner = false
                    })
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
            
            // Splash screen
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
            // Splash per 2.5 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
            // Clipboard check dopo splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                checkClipboard()
            }
        }
    }
    
    private func checkClipboard() {
        guard let content = UIPasteboard.general.string else { return }
        let cleaned = content.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if cleaned.count >= 8 && cleaned.count <= 16 {
            let digits = cleaned.filter { $0.isNumber || $0 == "+" }
            if digits.count >= 8 {
                clipboardNumber = APIService.cleanPhoneNumber(content)
                withAnimation(.spring(response: 0.4)) {
                    showClipboardBanner = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    withAnimation { showClipboardBanner = false }
                }
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.11, blue: 0.14)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Se l'immagine "splash_bruno" è in Assets, usa Image("splash_bruno")
                // Altrimenti usa il fallback testuale
                if UIImage(named: "splash_bruno") != nil {
                    Image("splash_bruno")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    // Fallback testuale
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
                
                Spacer()
            }
        }
    }
}

// MARK: - Clipboard Banner

struct ClipboardBanner: View {
    let number: String
    let onReport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.77, green: 0.64, blue: 0.27))
            
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
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(6)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Onboarding

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
                    // Pagina 1
                    VStack(spacing: 24) {
                        Spacer()
                        Text("🛡️")
                            .font(.system(size: 80))
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
                    }
                    .tag(0)
                    
                    // Pagina 2
                    VStack(spacing: 24) {
                        Spacer()
                        Text("📞")
                            .font(.system(size: 80))
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
                    }
                    .tag(1)
                    
                    // Pagina 3
                    VStack(spacing: 24) {
                        Spacer()
                        Text("⚙️")
                            .font(.system(size: 80))
                        Text("Attiva la protezione")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Serve un passaggio nelle impostazioni di iOS:")
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
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Apri Impostazioni")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        Spacer()
                    }
                    .tag(2)
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

