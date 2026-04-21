import SwiftUI

struct ContentView: View {
    @State private var service = GameScheduleService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    AlertBannerView(status: service.trafficStatus)
                    TrafficButtonView()
                    CommuteStripView(duration: service.commuteDuration)
                    CommuteMapView(route: service.route)
                    SectionLabel(text: "Upcoming Home Games · Next 10 Days")
                    GameListView(games: service.games, trafficStatus: service.trafficStatus)
                    FooterView(lastUpdated: service.lastUpdated)
                }
            }
            .background(Color(hex: "0D0D0D"))
            .scrollContentBackground(.hidden)
            .navigationTitle("⚾ Giants Commute Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "FD5A1E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await service.fetch() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(.white)
                }
            }
        }
        .task {
            service.startAutoRefresh()
        }
        .onDisappear {
            service.stopAutoRefresh()
        }
    }
}

// MARK: - Traffic Button

struct TrafficButtonView: View {
    var body: some View {
        Link(destination: URL(string: "https://www.google.com/maps/dir/901+Cherry+Ave,+San+Bruno,+CA/333+Beale+St,+San+Francisco,+CA")!) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .semibold))
                Text("Check Traffic Now")
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(Color(hex: "4285F4"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "4285F4").opacity(0.35), radius: 8, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }
}

// MARK: - Commute Strip

struct CommuteStripView: View {
    let duration: String?

    var body: some View {
        VStack(spacing: 6) {
            Text("🚗 901 Cherry Ave, San Bruno → 333 Beale St, SF")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "888888"))
                .lineLimit(1)
                .truncationMode(.tail)

            if let duration {
                Text(duration)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color(hex: "5cb85c"))
            } else {
                Text("fetching…")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "888888"))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(Color(hex: "888888"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
    }
}

// MARK: - Game List

struct GameListView: View {
    let games: [Game]
    let trafficStatus: TrafficStatus

    var body: some View {
        if games.isEmpty {
            Text("No home games in the next 10 days")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "888888"))
                .padding(.vertical, 28)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(games) { game in
                    GameRowView(game: game)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Footer

struct FooterView: View {
    let lastUpdated: Date?

    private var updatedText: String {
        guard let date = lastUpdated else { return "—" }
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return "Updated \(fmt.string(from: date))"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(updatedText) · auto-refreshes every 5 min")
            Text("San Bruno (YouTube HQ) → 333 Beale St, SF")
        }
        .font(.system(size: 11))
        .foregroundStyle(Color(hex: "444444"))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

#Preview {
    ContentView()
}
