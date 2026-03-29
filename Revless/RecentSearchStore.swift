// RecentSearchStore.swift
// Revless
//
// Persists successful route searches for the Home "Recent Activity" section.
// Dedupes by origin + destination + departure date (latest attempt wins).

import Foundation
import Observation

struct RecentSearchActivity: Codable, Identifiable, Equatable {
    let id: UUID
    let origin: String
    let destination: String
    /// yyyy-MM-dd (API / dedupe key)
    let departureDate: String
    let travelerTypeRaw: String
    let totalFiltered: Int
    let totalRaw: Int
    let searchedAt: Date

    var routeLabel: String { "\(origin) → \(destination)" }

    var travelerDisplay: String {
        TravelerType(rawValue: travelerTypeRaw)?.displayName ?? travelerTypeRaw.capitalized
    }

    var resultSummary: String {
        guard totalRaw > 0 else { return "No routes returned" }
        let dropped = totalRaw - totalFiltered
        if dropped == 0 {
            return "\(totalFiltered) route\(totalFiltered == 1 ? "" : "s") eligible"
        }
        return "\(totalFiltered) of \(totalRaw) eligible · \(dropped) filtered"
    }

    /// e.g. "Apr 5" from stored `yyyy-MM-dd`.
    var departureDisplay: String {
        guard let date = Self.fallbackDayParse.date(from: departureDate) else {
            return departureDate
        }
        return Self.dayOut.string(from: date)
    }

    private static let fallbackDayParse: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    private static let dayOut: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

@Observable
final class RecentSearchStore {

    private static let defaultsKey = "revless.recentSearchActivity.v1"
    private static let maxEntries = 12

    private(set) var items: [RecentSearchActivity] = []

    init() {
        load()
    }

    /// Call after a successful `/search/routes` response (including zero results).
    func recordSuccessfulSearch(
        origin: String,
        destination: String,
        departureDate: String,
        travelerType: TravelerType,
        totalFiltered: Int,
        totalRaw: Int
    ) {
        let o = origin.uppercased().trimmingCharacters(in: .whitespaces)
        let d = destination.uppercased().trimmingCharacters(in: .whitespaces)
        var next = items.filter { !($0.origin == o && $0.destination == d && $0.departureDate == departureDate) }

        let entry = RecentSearchActivity(
            id: UUID(),
            origin: o,
            destination: d,
            departureDate: departureDate,
            travelerTypeRaw: travelerType.rawValue,
            totalFiltered: totalFiltered,
            totalRaw: totalRaw,
            searchedAt: Date()
        )
        next.insert(entry, at: 0)
        items = Array(next.prefix(Self.maxEntries))
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey) else {
            items = []
            return
        }
        if let decoded = try? JSONDecoder().decode([RecentSearchActivity].self, from: data) {
            items = decoded
        } else {
            items = []
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
