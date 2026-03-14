import SwiftUI

struct ContentView: View {
    @Environment(EpisodeStore.self) private var store
    @State private var selectedTab = "journal"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "tab.journal"), systemImage: "list.bullet", value: "journal") {
                JournalView(store: store)
            }
            Tab(String(localized: "tab.stats"), systemImage: "chart.bar", value: "stats") {
                StatsView(store: store)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

#Preview {
    ContentView()
        .environment(EpisodeStore())
}
