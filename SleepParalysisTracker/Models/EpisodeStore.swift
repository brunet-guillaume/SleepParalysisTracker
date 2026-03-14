import Foundation
import SwiftUI
import WidgetKit

@Observable
final class EpisodeStore {
    var episodes: [Episode] = []

    private let fileURL: URL

    init() {
        let iCloudBase = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        let appFolder = iCloudBase.appendingPathComponent("SleepParalysisTracker")
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.fileURL = appFolder.appendingPathComponent("episodes.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            episodes = try decoder.decode([Episode].self, from: data)
            episodes.sort { $0.date > $1.date }
        } catch {
            print("Erreur de chargement: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(episodes)
            try data.write(to: fileURL, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Erreur de sauvegarde: \(error)")
        }
    }

    func add(_ episode: Episode) {
        episodes.insert(episode, at: 0)
        save()
    }

    func update(_ episode: Episode) {
        if let index = episodes.firstIndex(where: { $0.id == episode.id }) {
            episodes[index] = episode
            episodes.sort { $0.date > $1.date }
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        episodes.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        episodes.removeAll { $0.id == id }
        save()
    }

    // MARK: - Stats

    var totalCount: Int { episodes.count }

    var averageStress: Double {
        guard !episodes.isEmpty else { return 0 }
        return Double(episodes.map(\.stressLevel).reduce(0, +)) / Double(episodes.count)
    }

    var hallucinationPercentage: Double {
        guard !episodes.isEmpty else { return 0 }
        let count = episodes.filter(\.hasHallucination).count
        return Double(count) / Double(episodes.count) * 100
    }

    func triggerBreakdown() -> [(trigger: Trigger, count: Int)] {
        var counts: [Trigger: Int] = [:]
        for episode in episodes {
            for trigger in episode.triggers {
                counts[trigger, default: 0] += 1
            }
        }
        return counts.map { (trigger: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func hallucinationTypeBreakdown() -> [(type: HallucinationType, count: Int)] {
        var counts: [HallucinationType: Int] = [:]
        for episode in episodes where episode.hasHallucination {
            for type in episode.hallucinationTypes {
                counts[type, default: 0] += 1
            }
        }
        return counts.map { (type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func averageStressByDay() -> [(date: Date, averageStress: Double)] {
        let calendar = Calendar.current
        var grouped: [DateComponents: [Int]] = [:]
        for episode in episodes {
            let day = calendar.dateComponents([.year, .month, .day], from: episode.date)
            grouped[day, default: []].append(episode.stressLevel)
        }
        return grouped.compactMap { day, levels in
            guard let date = calendar.date(from: day) else { return nil }
            let avg = Double(levels.reduce(0, +)) / Double(levels.count)
            return (date: date, averageStress: avg)
        }
        .sorted { $0.date < $1.date }
    }

    func episodesByMonth() -> [(month: String, count: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "fr_FR")

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"
        displayFormatter.locale = Locale(identifier: "fr_FR")

        var grouped: [String: (display: String, count: Int, date: Date)] = [:]
        for episode in episodes {
            let key = formatter.string(from: episode.date)
            if grouped[key] != nil {
                grouped[key]!.count += 1
            } else {
                grouped[key] = (display: displayFormatter.string(from: episode.date).capitalized, count: 1, date: episode.date)
            }
        }
        return grouped.values
            .sorted { $0.date < $1.date }
            .map { (month: $0.display, count: $0.count) }
    }

    func groupedByMonth() -> [(month: String, episodes: [Episode])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")

        var grouped: [String: (date: Date, episodes: [Episode])] = [:]
        for episode in episodes {
            let key = formatter.string(from: episode.date).capitalized
            if grouped[key] != nil {
                grouped[key]!.episodes.append(episode)
            } else {
                grouped[key] = (date: episode.date, episodes: [episode])
            }
        }
        return grouped.map { (month: $0.key, episodes: $0.value.episodes) }
            .sorted { $0.episodes.first!.date > $1.episodes.first!.date }
    }
}
