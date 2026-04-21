import SwiftUI

struct GameRowView: View {
    let game: Game

    private var pitch: Date { game.gameDate }
    private var window: TrafficWindow { TrafficWindow(gameDate: pitch) }
    private var now: Date { Date() }
    private var isLive: Bool { game.status.abstractGameState == "Live" }
    private var isFinal: Bool { game.status.abstractGameState == "Final" }
    private var isToday: Bool { Calendar.current.isDateInToday(pitch) }
    private var inWindow: Bool { now >= window.start && now <= window.end }
    private var opponent: String { game.teams.away.team.name }

    private var borderColor: Color? {
        if inWindow || isLive { return Color(hex: "C0392B") }
        if isToday { return Color(hex: "FD5A1E") }
        return nil
    }

    private var cardBackground: Color {
        if inWindow || isLive { return Color(hex: "2A1515") }
        if isToday { return Color(hex: "221510") }
        return Color(hex: "1E1E1E")
    }

    var body: some View {
        HStack(spacing: 12) {
            dateColumn
            infoColumn
            Spacer(minLength: 0)
            badgeColumn
        }
        .padding(.vertical, 14)
        .padding(.leading, borderColor != nil ? 13 : 16)
        .padding(.trailing, 14)
        .background(cardBackground)
        .overlay(alignment: .leading) {
            if let color = borderColor {
                color.frame(width: 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sub-views

    private var dateColumn: some View {
        VStack(spacing: 1) {
            Text(pitch.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Color(hex: "888888"))
            Text("\(Calendar.current.component(.day, from: pitch))")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(.white)
            Text(pitch.formatted(.dateTime.month(.abbreviated)).uppercased())
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "888888"))
        }
        .frame(width: 54)
    }

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("vs \(opponent)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("\(isFinal ? "Final" : fmtTime(pitch)) · Oracle Park")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "AAAAAA"))
            if let note = windowNote {
                Text(note)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "E07050"))
            }
        }
    }

    @ViewBuilder
    private var badgeColumn: some View {
        if isLive {
            BadgeView(text: "LIVE", bg: Color(hex: "C0392B"), fg: .white)
                .modifier(PulseModifier())
        } else if inWindow {
            BadgeView(text: "TRAFFIC", bg: Color(hex: "8B1A1A"), fg: Color(hex: "FFAAAA"))
        } else if isToday && !isFinal {
            BadgeView(text: "TODAY", bg: Color(hex: "3A1A00"), fg: Color(hex: "FD5A1E"))
        } else if !isFinal {
            BadgeView(
                text: pitch.formatted(.dateTime.weekday(.abbreviated)).uppercased(),
                bg: Color(hex: "222222"),
                fg: Color(hex: "BBBBBB")
            )
        }
    }

    // MARK: - Helpers

    private var windowNote: String? {
        if isToday && !isFinal && now < window.start {
            return "Traffic impact \(fmtTime(window.start))–\(fmtTime(window.end))"
        }
        if inWindow {
            return "Impact window ends \(fmtTime(window.end))"
        }
        return nil
    }

    private func fmtTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
}

// MARK: - Badge

struct BadgeView: View {
    let text: String
    let bg: Color
    let fg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.5)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - Pulse animation (mirrors the CSS @keyframes pulse on the LIVE badge)

struct PulseModifier: ViewModifier {
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    opacity = 0.55
                }
            }
    }
}
