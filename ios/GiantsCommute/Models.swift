import Foundation

// MARK: - MLB API Response Models

struct MLBScheduleResponse: Decodable, Sendable {
    let dates: [DateGroup]
}

struct DateGroup: Decodable, Sendable {
    let games: [Game]
}

struct Game: Decodable, Identifiable, Sendable {
    let gamePk: Int
    let gameDate: Date
    let status: GameStatus
    let teams: GameTeams

    var id: Int { gamePk }
}

struct GameStatus: Decodable, Sendable {
    let abstractGameState: String?
}

struct GameTeams: Decodable, Sendable {
    let home: GameTeamEntry
    let away: GameTeamEntry
}

struct GameTeamEntry: Decodable, Sendable {
    let team: Team
}

struct Team: Decodable, Sendable {
    let id: Int
    let name: String
}

// MARK: - Traffic Window

struct TrafficWindow: Sendable {
    static let beforeHours: Double = 3
    static let afterHours: Double = 2

    let pitch: Date
    let start: Date
    let end: Date

    init(gameDate: Date) {
        pitch = gameDate
        start = gameDate.addingTimeInterval(-TrafficWindow.beforeHours * 3_600)
        end = gameDate.addingTimeInterval(TrafficWindow.afterHours * 3_600)
    }
}

// MARK: - Traffic Status

enum TrafficStatus: Sendable {
    case loading
    case noGame
    case upcoming(game: Game, pitch: Date, start: Date)
    case active(game: Game, end: Date)
    case past(opponent: String)
    case error(String)
}
