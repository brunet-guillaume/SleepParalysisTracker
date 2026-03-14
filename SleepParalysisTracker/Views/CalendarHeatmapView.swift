import SwiftUI

struct CalendarHeatmapView: View {
    let episodes: [Episode]
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let dayNames = [(0, "L"), (1, "M"), (2, "M"), (3, "J"), (4, "V"), (5, "S"), (6, "D")]

    private var episodesByDay: [String: [Episode]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var result: [String: [Episode]] = [:]
        for episode in episodes {
            let key = formatter.string(from: episode.date)
            result[key, default: []].append(episode)
        }
        return result
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).capitalized
    }

    private var daysInMonth: [DateComponents] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return range.map {
            DateComponents(year: components.year, month: components.month, day: $0)
        }
    }

    private var firstWeekdayOffset: Int {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let firstDay = calendar.date(from: components)!
        // Monday = 0, Sunday = 6
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7
    }

    var body: some View {
        GroupBox("stats.calendar") {
            VStack(spacing: 12) {
                // Navigation mois
                HStack {
                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Text(monthTitle)
                        .font(.headline)
                    Spacer()

                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                // En-têtes
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(dayNames, id: \.0) { _, name in
                        Text(name)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Grille des jours
                let cells = buildCells()
                let rowCount = max(1, (cells.count + 6) / 7)
                GeometryReader { geo in
                    let cellHeight = max(32, (geo.size.height - CGFloat(rowCount - 1) * 4) / CGFloat(rowCount))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                        ForEach(cells) { cell in
                            if let day = cell.day {
                                DayCellView(
                                    day: day,
                                    episodes: cell.episodes,
                                    isToday: cell.isToday
                                )
                                .frame(height: cellHeight)
                            } else {
                                Color.clear
                                    .frame(height: cellHeight)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }

    private func buildCells() -> [CalendarCell] {
        var cells: [CalendarCell] = []
        for i in 0..<firstWeekdayOffset {
            cells.append(CalendarCell(id: -i - 1, day: nil, episodes: [], isToday: false))
        }
        for components in daysInMonth {
            let date = calendar.date(from: components)!
            let key = dayKey(date)
            cells.append(CalendarCell(
                id: components.day!,
                day: components.day!,
                episodes: episodesByDay[key] ?? [],
                isToday: calendar.isDateInToday(date)
            ))
        }
        return cells
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct CalendarCell: Identifiable {
    let id: Int
    let day: Int?
    let episodes: [Episode]
    let isToday: Bool
}

struct DayCellView: View {
    let day: Int
    let episodes: [Episode]
    let isToday: Bool

    var body: some View {
        ZStack {
            if !episodes.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellColor.opacity(0.7))
            } else if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.primary.opacity(0.3), lineWidth: 1)
            }

            VStack(spacing: 1) {
                Text("\(day)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(!episodes.isEmpty ? .white : .primary)

                if !episodes.isEmpty {
                    Text("\(episodes.count)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(height: 32)
        .help(tooltip)
    }

    private var cellColor: Color {
        guard let maxStress = episodes.map(\.stressLevel).max() else { return .clear }
        switch maxStress {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }

    private var tooltip: String {
        guard !episodes.isEmpty else { return "" }
        let count = episodes.count
        let maxStress = episodes.map(\.stressLevel).max() ?? 0
        let hasHallucination = episodes.contains(where: \.hasHallucination)
        var text = String(format: String(localized: "calendar.tooltip.episodes"), count, maxStress)
        if hasHallucination { text += String(localized: "calendar.tooltip.hallucination") }
        return text
    }
}

#Preview {
    let episodes = [
        Episode(date: .now, stressLevel: 8, hasHallucination: true, hallucinationTypes: [.visual]),
        Episode(date: .now, stressLevel: 6, hasHallucination: false),
        Episode(date: .now.addingTimeInterval(-86400 * 2), stressLevel: 3, hasHallucination: false),
        Episode(date: .now.addingTimeInterval(-86400 * 7), stressLevel: 9, hasHallucination: true, hallucinationTypes: [.auditory]),
        Episode(date: .now.addingTimeInterval(-86400 * 14), stressLevel: 5, hasHallucination: true, hallucinationTypes: [.presence]),
    ]
    return CalendarHeatmapView(episodes: episodes)
        .padding()
        .frame(width: 400)
}
