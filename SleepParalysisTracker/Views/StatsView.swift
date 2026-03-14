import SwiftUI
import Charts

struct MonthOption: Hashable {
    let date: Date
    let label: String
}

struct StatsView: View {
    var store: EpisodeStore
    @State private var startMonth: Date = Date()
    @State private var endMonth: Date = Date()
    @State private var initialized = false

    private var allMonths: [MonthOption] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let oldest = store.episodes.min(by: { $0.date < $1.date })?.date else { return [] }

        let startComponents = calendar.dateComponents([.year, .month], from: oldest)
        var current = calendar.date(from: startComponents)!
        let now = Date()
        var months: [MonthOption] = []

        while current <= now {
            months.append(MonthOption(date: current, label: formatter.string(from: current).capitalized))
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }
        return months.reversed()
    }

    private var startMonthOptions: [MonthOption] {
        allMonths.filter { $0.date <= endMonth }
    }

    private var endMonthOptions: [MonthOption] {
        allMonths.filter { $0.date >= startMonth }
    }

    private var filteredEpisodes: [Episode] {
        let calendar = Calendar.current
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: endMonth)!
        return store.episodes.filter { $0.date >= startMonth && $0.date <= endOfMonth }
    }

    private var filteredStore: EpisodeStore {
        let s = EpisodeStore()
        s.episodes = filteredEpisodes
        return s
    }

    var body: some View {
        if store.episodes.isEmpty {
            ContentUnavailableView {
                Label("stats.empty.title", systemImage: "chart.bar")
            } description: {
                Text("stats.empty.description")
            }
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    HStack {
                        Picker("stats.period.from", selection: $startMonth) {
                            ForEach(startMonthOptions, id: \.self) { month in
                                Text(month.label).tag(month.date)
                            }
                        }
                        Picker("stats.period.to", selection: $endMonth) {
                            ForEach(endMonthOptions, id: \.self) { month in
                                Text(month.label).tag(month.date)
                            }
                        }
                    }
                    .onAppear {
                        guard !initialized, let last = allMonths.first else { return }
                        let calendar = Calendar.current
                        let sixMonthsAgo = calendar.date(byAdding: .month, value: -5, to: last.date)!
                        let sixMonthsComponents = calendar.dateComponents([.year, .month], from: sixMonthsAgo)
                        let sixMonthsStart = calendar.date(from: sixMonthsComponents)!
                        // Find the closest available month
                        startMonth = allMonths.last { $0.date >= sixMonthsStart }?.date ?? allMonths.last!.date
                        endMonth = last.date
                        initialized = true
                    }

                    // Summary cards
                    let episodes = filteredEpisodes
                    let totalCount = episodes.count
                    let avgStress = episodes.isEmpty ? 0.0 : Double(episodes.map(\.stressLevel).reduce(0, +)) / Double(totalCount)
                    let hallPercentage = episodes.isEmpty ? 0.0 : Double(episodes.filter(\.hasHallucination).count) / Double(totalCount) * 100

                    HStack(spacing: 16) {
                        StatCard(
                            title: String(localized: "stats.total"),
                            value: "\(totalCount)",
                            icon: "moon.zzz.fill",
                            color: .blue
                        )
                        StatCard(
                            title: String(localized: "stats.avg_stress"),
                            value: String(format: "%.1f", avgStress),
                            icon: "brain.head.profile",
                            color: stressColor(avgStress)
                        )
                        StatCard(
                            title: String(localized: "stats.with_hallucination"),
                            value: String(format: "%.0f%%", hallPercentage),
                            icon: "eye.trianglebadge.exclamationmark",
                            color: .purple
                        )
                    }

                    FlowLayout(spacing: 16) {
                        episodesPerMonthChart
                            .frame(minWidth: 250, minHeight: 300)

                        hallucinationTypeChart
                            .frame(minWidth: 250, minHeight: 300)

                        CalendarHeatmapView(episodes: filteredEpisodes)
                            .frame(minWidth: 250, minHeight: 300)

                        triggersChart
                            .frame(minWidth: 250, minHeight: 300)

                        stressOverTimeChart
                            .frame(minWidth: 350, minHeight: 300)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private var episodesPerMonthChart: some View {
        let monthlyData = filteredStore.episodesByMonth()
        if !monthlyData.isEmpty {
            GroupBox("stats.episodes_per_month") {
                Chart(monthlyData, id: \.month) { item in
                    BarMark(
                        x: .value(String(localized: "chart.month"), item.month),
                        y: .value(String(localized: "chart.count"), item.count)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(orientation: .vertical)
                    }
                }
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var hallucinationTypeChart: some View {
        let typeData = filteredStore.hallucinationTypeBreakdown()
        if !typeData.isEmpty {
            GroupBox("stats.hallucination_types") {
                Chart(typeData, id: \.type) { item in
                    SectorMark(
                        angle: .value(String(localized: "chart.count"), item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.type.color)
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(
                    domain: typeData.map(\.type.label),
                    range: typeData.map(\.type.color)
                )
                .chartLegend(spacing: 12)
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var triggersChart: some View {
        let triggerData = filteredStore.triggerBreakdown()
        if !triggerData.isEmpty {
            GroupBox("stats.triggers") {
                Chart(triggerData, id: \.trigger) { item in
                    SectorMark(
                        angle: .value(String(localized: "chart.count"), item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.trigger.color)
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(
                    domain: triggerData.map(\.trigger.label),
                    range: triggerData.map(\.trigger.color)
                )
                .chartLegend(spacing: 12)
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var stressOverTimeChart: some View {
        let dailyStress = filteredStore.averageStressByDay()
        if dailyStress.count > 1 {
            GroupBox("stats.stress_over_time") {
                Chart(dailyStress, id: \.date) { item in
                    LineMark(
                        x: .value(String(localized: "chart.date"), item.date),
                        y: .value(String(localized: "chart.stress"), item.averageStress)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.orange.gradient)

                    PointMark(
                        x: .value(String(localized: "chart.date"), item.date),
                        y: .value(String(localized: "chart.stress"), item.averageStress)
                    )
                    .foregroundStyle(.orange)
                }
                .chartYScale(domain: 1...10)
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func stressColor(_ value: Double) -> Color {
        switch value {
        case 0..<4: return .green
        case 4..<7: return .orange
        default: return .red
        }
    }
}

#Preview {
    let store = EpisodeStore()
    store.episodes = [
        Episode(date: .now, stressLevel: 8, hasHallucination: true, hallucinationTypes: [.visual, .presence]),
        Episode(date: .now.addingTimeInterval(-86400), stressLevel: 5, hasHallucination: false),
        Episode(date: .now.addingTimeInterval(-86400 * 8), stressLevel: 9, hasHallucination: true, hallucinationTypes: [.auditory]),
        Episode(date: .now.addingTimeInterval(-86400 * 15), stressLevel: 3, hasHallucination: true, hallucinationTypes: [.tactile]),
        Episode(date: .now.addingTimeInterval(-86400 * 30), stressLevel: 6, hasHallucination: false),
    ]
    return StatsView(store: store)
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
