import SwiftUI

struct FeedView: View {
    @State private var feedItems: [FeedItem] = []
    @State private var stats: StatsResponse?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Stats bar
                    if let stats = stats {
                        HStack(spacing: 8) {
                            StatChip(value: "\(stats.total_numbers_tracked)", label: "Numeri")
                            StatChip(value: "\(stats.total_reports)", label: "Segnalazioni")
                            StatChip(value: "\(stats.high_risk_numbers)", label: "Alto rischio")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Feed list
                    if isLoading {
                        ProgressView("Caricamento...")
                            .padding(40)
                    } else if feedItems.isEmpty {
                        Text("Nessuna segnalazione ancora")
                            .foregroundColor(.gray)
                            .padding(40)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(feedItems) { item in
                                FeedItemRow(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Feed")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        do {
            async let feedResult = APIService.shared.feed()
            async let statsResult = APIService.shared.stats()
            
            let (items, statsData) = try await (feedResult, statsResult)
            
            await MainActor.run {
                feedItems = items
                stats = statsData
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct FeedItemRow: View {
    let item: FeedItem
    
    var scoreColor: Color {
        if item.spam_score >= 70 { return .red }
        if item.spam_score >= 40 { return .orange }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Score badge
            Text("\(item.spam_score)")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(scoreColor)
                .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.number_masked)
                    .font(.system(size: 15, weight: .bold))
                Text(item.category_label + (item.operator_name.map { " · \($0)" } ?? ""))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Reports count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.total_reports)")
                    .font(.system(size: 16, weight: .bold))
                Text("segnalazioni")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct StatChip: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.blue)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
