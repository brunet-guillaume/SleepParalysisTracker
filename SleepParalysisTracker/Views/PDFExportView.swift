import SwiftUI

struct PDFExportView: View {
    @Environment(\.dismiss) private var dismiss
    let episodes: [Episode]

    @State private var startMonth: Date = Date()
    @State private var endMonth: Date = Date()
    @State private var initialized = false

    private var allMonths: [MonthOption] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let oldest = episodes.min(by: { $0.date < $1.date })?.date else { return [] }

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
        return episodes.filter { $0.date >= startMonth && $0.date <= endOfMonth }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("journal.export_pdf")
                .font(.headline)

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

            Text("\(filteredEpisodes.count) \(String(localized: "pdf.episodes_count"))")
                .foregroundStyle(.secondary)

            HStack {
                Button("form.cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("pdf.export") {
                    PDFExporter.export(episodes: filteredEpisodes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(filteredEpisodes.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 450)
        .onAppear {
            guard !initialized, let first = allMonths.last, let last = allMonths.first else { return }
            startMonth = first.date
            endMonth = last.date
            initialized = true
        }
    }
}
