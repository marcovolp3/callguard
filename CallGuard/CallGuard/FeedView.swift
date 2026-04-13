import SwiftUI

struct FeedView: View {
    @State private var feedItems: [FeedItem] = []
    @State private var stats: StatsResponse?
    @State private var isLoading = true
    
    let darkBg = Color(red: 0.08, green: 0.11, blue: 0.14)
    let gold = Color(red: 0.77, green: 0.64, blue: 0.27)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header con stats
                VStack(spacing: 16) {
                    Text("Community")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let stats = stats {
                        HStack(spacing: 12) {
                            StatBadge(value: "\(stats.total_numbers_tracked)", label: "Numeri", icon: "phone.fill")
                            StatBadge(value: "\(stats.total_reports)", label: "Segnalazioni", icon: "flag.fill")
                            StatBadge(value: "\(stats.high_risk_numbers)", label: "Pericolosi", icon: "exclamationmark.shield.fill")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(darkBg)
                
                // Feed
                VStack(spacing: 10) {
                    if isLoading {
                        ProgressView("Caricamento...")
                            .padding(40)
                    } else if feedItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Nessuna segnalazione ancora")
                                .foregroundColor(.gray)
                        }
                        .padding(40)
                    } else {
                        ForEach(feedItems) { item in
                            FeedCard(item: item)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
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

struct FeedCard: View {
    let item: FeedItem
    
    var scoreColor: Color {
        if item.spam_score >= 70 { return .red }
        if item.spam_score >= 40 { return .orange }
        return .green
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Score
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Text("\(item.spam_score)")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(scoreColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.number_masked)
                    .font(.system(size: 15, weight: .bold))
                HStack(spacing: 4) {
                    Text(item.category_label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(scoreColor.opacity(0.8))
                        .cornerRadius(6)
                    if let op = item.operator_name {
                        Text(op)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Reports
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.total_reports)")
                    .font(.system(size: 18, weight: .bold))
                Text("segnalaz.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                if item.trend == "rising" {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("attivo")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.77, green: 0.64, blue: 0.27))
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

