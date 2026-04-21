import Foundation
import MapKit
import Observation

@Observable
@MainActor
final class GameScheduleService {
    static let giantsTeamId = 137
    static let lookaheadDays = 10
    static let refreshInterval: TimeInterval = 5 * 60

    // 901 Cherry Ave, San Bruno → 333 Beale St, SF
    private static let origin      = CLLocationCoordinate2D(latitude: 37.6290, longitude: -122.4212)
    private static let destination = CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.3934)

    var games: [Game] = []
    var trafficStatus: TrafficStatus = .loading
    var commuteDuration: String?
    var route: MKRoute?
    var lastUpdated: Date?

    private var refreshTask: Task<Void, Never>?

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await fetch()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.refreshInterval))
                guard !Task.isCancelled else { break }
                await fetch()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func fetch() async {
        // Fetch games and commute info concurrently; MKRoute is non-Sendable so
        // fetchCommuteInfo() is called after the async-let games result is awaited.
        async let gamesFetch: [Game] = fetchHomeGames()

        do {
            let fetched = try await gamesFetch
            games = fetched
            trafficStatus = computeTrafficStatus(games: fetched)
            lastUpdated = Date()
        } catch {
            trafficStatus = .error(error.localizedDescription)
        }

        if let info = await fetchCommuteInfo() {
            commuteDuration = info.duration
            route = info.route
        }
    }

    private func fetchCommuteInfo() async -> (duration: String, route: MKRoute)? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: Self.origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: Self.destination))
        request.transportType = .automobile
        request.departureDate = Date()
        request.requestsAlternateRoutes = false

        guard let response = try? await MKDirections(request: request).calculate(),
              let route = response.routes.first else { return nil }
        let minutes = Int(route.expectedTravelTime / 60)
        return ("\(minutes) min with traffic", route)
    }

    private func fetchHomeGames() async throws -> [Game] {
        let today = Date()
        let end = Calendar.current.date(byAdding: .day, value: Self.lookaheadDays, to: today)!

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        var components = URLComponents(string: "https://statsapi.mlb.com/api/v1/schedule")!
        components.queryItems = [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "teamId", value: "\(Self.giantsTeamId)"),
            URLQueryItem(name: "startDate", value: dateFmt.string(from: today)),
            URLQueryItem(name: "endDate", value: dateFmt.string(from: end)),
            URLQueryItem(name: "gameType", value: "R,P,F,D,L,W"),
            URLQueryItem(name: "hydrate", value: "team"),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)

        let decoder = JSONDecoder()
        // MLB API returns ISO 8601 dates like "2025-04-20T20:15:00Z"
        decoder.dateDecodingStrategy = .iso8601

        let response = try decoder.decode(MLBScheduleResponse.self, from: data)
        return response.dates
            .flatMap(\.games)
            .filter { $0.teams.home.team.id == Self.giantsTeamId }
    }

    private func computeTrafficStatus(games: [Game]) -> TrafficStatus {
        let now = Date()
        let todayGames = games.filter { Calendar.current.isDateInToday($0.gameDate) }

        guard !todayGames.isEmpty else { return .noGame }

        for game in todayGames {
            let window = TrafficWindow(gameDate: game.gameDate)
            let isLive = game.status.abstractGameState == "Live"
            let opponent = game.teams.away.team.name

            if isLive || (now >= window.start && now <= window.end) {
                return .active(game: game, end: window.end)
            }
            if now < window.start {
                return .upcoming(game: game, pitch: window.pitch, start: window.start)
            }
            return .past(opponent: opponent)
        }

        return .noGame
    }
}
