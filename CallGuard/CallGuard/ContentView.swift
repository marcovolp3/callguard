import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Cerca")
                }
                .tag(0)
            
            ReportView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Segnala")
                }
                .tag(1)
            
            FeedView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Feed")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Impostazioni")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}
