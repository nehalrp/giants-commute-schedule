import SwiftUI

struct AlertBannerView: View {
    let status: TrafficStatus

    private var config: BannerConfig {
        switch status {
        case .loading:
            return BannerConfig(
                color: Color(hex: "2A2A2A"),
                title: "Checking schedule…",
                subtitle: "Loading Giants home games"
            )
        case .noGame:
            return BannerConfig(
                color: Color(hex: "1A7A40"),
                title: "✅ No Game Impact Today",
                subtitle: "No Giants home game today — commute should be normal"
            )
        case .upcoming(let game, let pitch, let start):
            let opponent = game.teams.away.team.name
            return BannerConfig(
                color: Color(hex: "B7770D"),
                title: "⚠️ Game Today — Plan Your Commute",
                subtitle: "vs \(opponent) · First pitch \(fmtTime(pitch))",
                detail: "Traffic impact starts \(fmtTime(start))"
            )
        case .active(let game, let end):
            let opponent = game.teams.away.team.name
            return BannerConfig(
                color: Color(hex: "C0392B"),
                title: "🔴 GAME ALERT — HEAVY TRAFFIC",
                subtitle: "Home vs \(opponent)",
                detail: "Traffic window ends \(fmtTime(end))"
            )
        case .past(let opponent):
            return BannerConfig(
                color: Color(hex: "1A7A40"),
                title: "✅ Traffic Impact Has Passed",
                subtitle: "Game vs \(opponent) is winding down — traffic should be clearing"
            )
        case .error:
            return BannerConfig(
                color: Color(hex: "3A2A0A"),
                title: "⚠️ Couldn't Load Schedule",
                subtitle: "Check your connection — will retry in 5 min"
            )
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(config.title)
                .font(.system(size: 20, weight: .heavy))
                .multilineTextAlignment(.center)
            Text(config.subtitle)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .opacity(0.88)
            if let detail = config.detail {
                Text(detail)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .opacity(0.88)
            }
        }
        .foregroundStyle(.white)
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(config.color)
        .animation(.easeInOut(duration: 0.4), value: config.color)
    }

    private func fmtTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
}

private struct BannerConfig {
    let color: Color
    let title: String
    let subtitle: String
    var detail: String? = nil
}
