import SwiftUI
import Charts

struct StatsView: View {
    var store: EpisodeStore

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
                    // Summary cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: String(localized: "stats.total"),
                            value: "\(store.totalCount)",
                            icon: "moon.zzz.fill",
                            color: .blue
                        )
                        StatCard(
                            title: String(localized: "stats.avg_stress"),
                            value: String(format: "%.1f", store.averageStress),
                            icon: "brain.head.profile",
                            color: stressColor(store.averageStress)
                        )
                        StatCard(
                            title: String(localized: "stats.with_hallucination"),
                            value: String(format: "%.0f%%", store.hallucinationPercentage),
                            icon: "eye.trianglebadge.exclamationmark",
                            color: .purple
                        )
                    }
                    
                    FlowLayout(spacing: 16) {
                        episodesPerMonthChart
                            .frame(minWidth: 250, minHeight: 300)

                        hallucinationTypeChart
                            .frame(minWidth: 250, minHeight: 300)

                        CalendarHeatmapView(episodes: store.episodes)
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
        let monthlyData = store.episodesByMonth().suffix(12)
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
                .padding(16)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var hallucinationTypeChart: some View {
        let typeData = store.hallucinationTypeBreakdown()
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
        let triggerData = store.triggerBreakdown()
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
        if store.episodes.count > 1 {
            GroupBox("stats.stress_over_time") {
                let dailyStress = store.averageStressByDay()
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
