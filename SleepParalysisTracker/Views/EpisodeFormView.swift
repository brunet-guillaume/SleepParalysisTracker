import SwiftUI

struct EpisodeFormView: View {
    @Environment(\.dismiss) private var dismiss
    var store: EpisodeStore
    var editingEpisode: Episode?

    @State private var date: Date
    @State private var sliderValue: Double
    @State private var hasHallucination: Bool
    @State private var hallucinationTypes: Set<HallucinationType>
    @State private var sleepPosition: SleepPosition
    @State private var triggers: Set<Trigger>
    @State private var notes: String

    private var isEditing: Bool { editingEpisode != nil }
    private var stressLevel: Int { Int(sliderValue.rounded()) }

    init(store: EpisodeStore, editingEpisode: Episode? = nil) {
        self.store = store
        self.editingEpisode = editingEpisode
        _date = State(initialValue: editingEpisode?.date ?? Date())
        _sliderValue = State(initialValue: Double(editingEpisode?.stressLevel ?? 5))
        _hasHallucination = State(initialValue: editingEpisode?.hasHallucination ?? false)
        _hallucinationTypes = State(initialValue: editingEpisode?.hallucinationTypes ?? [])
        _sleepPosition = State(initialValue: editingEpisode?.sleepPosition ?? .unknown)
        _triggers = State(initialValue: editingEpisode?.triggers ?? [])
        _notes = State(initialValue: editingEpisode?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("form.when") {
                DatePicker("form.date", selection: $date)
            }

            Section("form.stress") {
                HStack {
                    Text("\(stressLevel)")
                        .font(.title2.bold())
                        .frame(width: 30)
                    Slider(value: $sliderValue, in: 1...10)
                }
                Text(stressLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("form.position") {
                Picker("form.position", selection: $sleepPosition) {
                    ForEach(SleepPosition.allCases) { position in
                        Label(position.label, systemImage: position.icon)
                            .tag(position)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("form.hallucination") {
                Toggle("form.hallucination.present", isOn: $hasHallucination)
                if hasHallucination {
                    ForEach(HallucinationType.allCases) { type in
                        Toggle(isOn: Binding(
                            get: { hallucinationTypes.contains(type) },
                            set: { isOn in
                                if isOn { hallucinationTypes.insert(type) }
                                else { hallucinationTypes.remove(type) }
                            }
                        )) {
                            Label(type.label, systemImage: type.icon)
                        }
                    }
                }
            }

            Section("form.triggers") {
                ForEach(Trigger.allCases) { trigger in
                    Toggle(isOn: Binding(
                        get: { triggers.contains(trigger) },
                        set: { isOn in
                            if isOn { triggers.insert(trigger) }
                            else { triggers.remove(trigger) }
                        }
                    )) {
                        Label(trigger.label, systemImage: trigger.icon)
                    }
                }
            }

            Section("form.notes") {
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 550)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("form.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? String(localized: "form.update") : String(localized: "form.save")) {
                    let episode = Episode(
                        id: editingEpisode?.id ?? UUID(),
                        date: date,
                        stressLevel: stressLevel,
                        hasHallucination: hasHallucination,
                        hallucinationTypes: hasHallucination ? hallucinationTypes : [],
                        sleepPosition: sleepPosition == .unknown ? nil : sleepPosition,
                        triggers: triggers,
                        notes: notes
                    )
                    if isEditing {
                        store.update(episode)
                    } else {
                        store.add(episode)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var stressLabel: String {
        switch stressLevel {
        case 1...3: return String(localized: "form.stress.low")
        case 4...6: return String(localized: "form.stress.moderate")
        case 7...8: return String(localized: "form.stress.high")
        case 9...10: return String(localized: "form.stress.very_high")
        default: return ""
        }
    }
}

#Preview {
    EpisodeFormView(store: EpisodeStore())
}
