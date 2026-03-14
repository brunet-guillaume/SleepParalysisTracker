import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @Environment(EpisodeStore.self) private var store
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    var openWindow: () -> Void
    var openAddForm: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("menubar.title")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Stats rapides
            HStack(spacing: 16) {
                VStack {
                    Text("\(monthCount)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("menubar.this_month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("\(store.totalCount)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("menubar.total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text(String(format: "%.1f", store.averageStress))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(stressColor)
                    Text("menubar.avg_stress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Dernier épisode
            if let last = store.episodes.first {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("menubar.last_episode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(last.date.formatted(.relative(presentation: .named)))
                            .font(.subheadline)
                    }
                    Spacer()
                    Text(String(format: String(localized: "menubar.stress"), last.stressLevel))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(stressColor(for: last.stressLevel).opacity(0.2), in: Capsule())
                }
            }

            Divider()

            // Actions
            Button {
                NSApp.keyWindow?.close()
                openAddForm()
            } label: {
                Label("menubar.new_episode", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                // Fermer le popover du menu bar
                NSApp.keyWindow?.close()
                openWindow()
            } label: {
                Label("menubar.open_journal", systemImage: "book")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

            Divider()

            Toggle("menubar.launch_at_login", isOn: $launchAtLogin)
                .foregroundStyle(.secondary)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Erreur login item: \(error)")
                        launchAtLogin = !newValue
                    }
                }
        }
        .padding()
        .frame(width: 300)
    }

    private var monthCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return store.episodes.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    private var stressColor: Color {
        switch store.averageStress {
        case 0..<4: return .green
        case 4..<7: return .orange
        default: return .red
        }
    }

    private func stressColor(for level: Int) -> Color {
        switch level {
        case 1...3: return .green
        case 4...6: return .orange
        case 7...10: return .red
        default: return .gray
        }
    }
}

#Preview {
    let store = EpisodeStore()
    store.episodes = [
        Episode(date: .now.addingTimeInterval(-3600), stressLevel: 7, hasHallucination: true, hallucinationTypes: [.visual]),
        Episode(date: .now.addingTimeInterval(-86400 * 3), stressLevel: 5, hasHallucination: false),
    ]
    return MenuBarView(openWindow: {}, openAddForm: {})
        .environment(store)
}
