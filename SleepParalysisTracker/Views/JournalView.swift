import SwiftUI

struct JournalView: View {
    var store: EpisodeStore
    @State private var showingAddSheet = false
    @State private var showingExportSheet = false
    @State private var editingEpisode: Episode?
    @State private var filterHallucination: Bool?
    @State private var filterPosition: SleepPosition?
    @State private var filterTrigger: Trigger?

    private var filteredEpisodes: [Episode] {
        store.episodes.filter { episode in
            if let filterHall = filterHallucination, episode.hasHallucination != filterHall {
                return false
            }
            if let filterPos = filterPosition, episode.sleepPosition != filterPos {
                return false
            }
            if let filterTrig = filterTrigger, !episode.triggers.contains(filterTrig) {
                return false
            }
            return true
        }
    }

    private func groupedFiltered() -> [(month: String, episodes: [Episode])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [String: (date: Date, episodes: [Episode])] = [:]
        for episode in filteredEpisodes {
            let key = formatter.string(from: episode.date).capitalized
            if grouped[key] != nil {
                grouped[key]!.episodes.append(episode)
            } else {
                grouped[key] = (date: episode.date, episodes: [episode])
            }
        }
        return grouped.map { (month: $0.key, episodes: $0.value.episodes.sorted { $0.date > $1.date }) }
            .sorted { $0.episodes.first!.date > $1.episodes.first!.date }
    }

    private var hasActiveFilters: Bool {
        filterHallucination != nil || filterPosition != nil || filterTrigger != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.episodes.isEmpty {
                ContentUnavailableView {
                    Label("journal.empty.title", systemImage: "moon.zzz")
                } description: {
                    Text("journal.empty.description")
                }
            } else {
                let groups = groupedFiltered()
                if groups.isEmpty {
                    ContentUnavailableView {
                        Label("journal.filter.no_results", systemImage: "magnifyingglass")
                    } description: {
                        Text("journal.filter.no_results_description")
                    }
                } else {
                    List {
                        ForEach(groups, id: \.month) { group in
                            Section(group.month) {
                                ForEach(group.episodes) { episode in
                                    EpisodeRow(episode: episode)
                                        .contextMenu {
                                            Button {
                                                editingEpisode = episode
                                            } label: {
                                                Label("journal.edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                store.delete(id: episode.id)
                                            } label: {
                                                Label("journal.delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("journal.add", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("journal.export_pdf", systemImage: "square.and.arrow.up")
                }
                .disabled(store.episodes.isEmpty)
            }
            ToolbarItem {
                Menu {
                    Section("form.hallucination") {
                        Button {
                            filterHallucination = filterHallucination == true ? nil : true
                        } label: {
                            Label("journal.filter.with_hallucination", systemImage: filterHallucination == true ? "checkmark.circle.fill" : "circle")
                        }
                        Button {
                            filterHallucination = filterHallucination == false ? nil : false
                        } label: {
                            Label("journal.filter.without_hallucination", systemImage: filterHallucination == false ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    Section("journal.filter.position") {
                        ForEach(SleepPosition.allCases) { pos in
                            Button {
                                filterPosition = filterPosition == pos ? nil : pos
                            } label: {
                                Label(pos.label, systemImage: filterPosition == pos ? "checkmark.circle.fill" : pos.icon)
                            }
                        }
                    }
                    Section("journal.filter.trigger") {
                        ForEach(Trigger.allCases) { trig in
                            Button {
                                filterTrigger = filterTrigger == trig ? nil : trig
                            } label: {
                                Label(trig.label, systemImage: filterTrigger == trig ? "checkmark.circle.fill" : trig.icon)
                            }
                        }
                    }
                    if hasActiveFilters {
                        Divider()
                        Button("journal.filter.reset") {
                            filterHallucination = nil
                            filterPosition = nil
                            filterTrigger = nil
                        }
                    }
                } label: {
                    Label("journal.filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            EpisodeFormView(store: store)
        }
        .sheet(item: $editingEpisode) { episode in
            EpisodeFormView(store: store, editingEpisode: episode)
        }
        .sheet(isPresented: $showingExportSheet) {
            PDFExportView(episodes: store.episodes)
        }
    }
}

struct EpisodeRow: View {
    let episode: Episode

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(stressColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("\(episode.stressLevel)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(stressColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: episode.date))
                    .font(.headline)

                HStack(spacing: 8) {
                    if episode.hasHallucination && !episode.hallucinationTypes.isEmpty {
                        ForEach(Array(episode.hallucinationTypes).sorted(by: { $0.label < $1.label })) { type in
                            Label(type.label, systemImage: type.icon)
                                .font(.caption)
                                .foregroundStyle(type.color)
                        }
                    } else {
                        Text("journal.no_hallucination")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let pos = episode.sleepPosition {
                        Label(pos.label, systemImage: pos.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !episode.triggers.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(episode.triggers).sorted(by: { $0.label < $1.label })) { trigger in
                            Label(trigger.label, systemImage: trigger.icon)
                                .font(.caption2)
                                .foregroundStyle(trigger.color)
                        }
                    }
                }

                if !episode.notes.isEmpty {
                    Text(episode.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var stressColor: Color {
        switch episode.stressLevel {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

#Preview("Journal vide") {
    JournalView(store: EpisodeStore())
}

#Preview("Journal avec données") {
    let store = EpisodeStore()
    store.episodes = [
        Episode(date: .now, stressLevel: 8, hasHallucination: true, hallucinationTypes: [.visual, .presence], sleepPosition: .back, triggers: [.stress, .lateScreen], notes: "Ombre dans la chambre"),
        Episode(date: .now.addingTimeInterval(-86400), stressLevel: 5, hasHallucination: false, sleepPosition: .side, notes: ""),
        Episode(date: .now.addingTimeInterval(-86400 * 3), stressLevel: 9, hasHallucination: true, hallucinationTypes: [.auditory], triggers: [.sleepDeprivation], notes: "Voix chuchotées"),
    ]
    return JournalView(store: store)
}
