import Foundation
import SwiftUI

enum HallucinationType: String, Codable, CaseIterable, Identifiable {
    case visual
    case auditory
    case tactile
    case presence
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .visual: return String(localized: "hallucination.visual")
        case .auditory: return String(localized: "hallucination.auditory")
        case .tactile: return String(localized: "hallucination.tactile")
        case .presence: return String(localized: "hallucination.presence")
        case .other: return String(localized: "hallucination.other")
        }
    }

    var color: Color {
        switch self {
        case .visual: return .blue
        case .auditory: return .green
        case .tactile: return .orange
        case .presence: return .purple
        case .other: return .gray
        }
    }

    var nsColor: NSColor {
        switch self {
        case .visual: return NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
        case .auditory: return NSColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1)
        case .tactile: return NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
        case .presence: return NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1)
        case .other: return NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        }
    }

    var icon: String {
        switch self {
        case .visual: return "eye"
        case .auditory: return "ear"
        case .tactile: return "hand.raised"
        case .presence: return "person.fill.questionmark"
        case .other: return "questionmark.circle"
        }
    }
}

enum SleepPosition: String, Codable, CaseIterable, Identifiable {
    case back
    case side
    case stomach
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .back: return String(localized: "position.back")
        case .side: return String(localized: "position.side")
        case .stomach: return String(localized: "position.stomach")
        case .unknown: return String(localized: "position.unknown")
        }
    }

    var icon: String {
        switch self {
        case .back: return "arrow.up.circle"
        case .side: return "arrow.left.circle"
        case .stomach: return "arrow.down.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

enum Trigger: String, Codable, CaseIterable, Identifiable {
    case stress
    case anxiety
    case depression
    case sleepDeprivation
    case jetlag
    case lateScreen
    case alcohol
    case caffeine
    case nap
    case irregularSchedule
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stress: return String(localized: "trigger.stress")
        case .anxiety: return String(localized: "trigger.anxiety")
        case .depression: return String(localized: "trigger.depression")
        case .sleepDeprivation: return String(localized: "trigger.sleep_deprivation")
        case .jetlag: return String(localized: "trigger.jetlag")
        case .lateScreen: return String(localized: "trigger.late_screen")
        case .alcohol: return String(localized: "trigger.alcohol")
        case .caffeine: return String(localized: "trigger.caffeine")
        case .nap: return String(localized: "trigger.nap")
        case .irregularSchedule: return String(localized: "trigger.irregular_schedule")
        case .other: return String(localized: "trigger.other")
        }
    }

    var icon: String {
        switch self {
        case .stress: return "brain.head.profile"
        case .anxiety: return "exclamationmark.triangle"
        case .depression: return "cloud.rain"
        case .sleepDeprivation: return "powersleep"
        case .jetlag: return "airplane"
        case .lateScreen: return "iphone"
        case .alcohol: return "wineglass"
        case .caffeine: return "cup.and.saucer"
        case .nap: return "bed.double"
        case .irregularSchedule: return "clock.badge.exclamationmark"
        case .other: return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .stress: return .red
        case .anxiety: return .pink
        case .depression: return .cyan
        case .sleepDeprivation: return .orange
        case .jetlag: return .blue
        case .lateScreen: return .indigo
        case .alcohol: return .purple
        case .caffeine: return .brown
        case .nap: return .teal
        case .irregularSchedule: return .yellow
        case .other: return .gray
        }
    }

    var nsColor: NSColor {
        switch self {
        case .stress: return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1)
        case .anxiety: return NSColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1)
        case .depression: return NSColor(red: 0.3, green: 0.7, blue: 0.85, alpha: 1)
        case .sleepDeprivation: return NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1)
        case .jetlag: return NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1)
        case .lateScreen: return NSColor(red: 0.35, green: 0.2, blue: 0.7, alpha: 1)
        case .alcohol: return NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1)
        case .caffeine: return NSColor(red: 0.55, green: 0.35, blue: 0.17, alpha: 1)
        case .nap: return NSColor(red: 0.2, green: 0.65, blue: 0.65, alpha: 1)
        case .irregularSchedule: return NSColor(red: 0.8, green: 0.7, blue: 0.0, alpha: 1)
        case .other: return NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        }
    }
}

struct Episode: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var stressLevel: Int = 5
    var hasHallucination: Bool = false
    var hallucinationTypes: Set<HallucinationType> = []
    var sleepPosition: SleepPosition?
    var triggers: Set<Trigger> = []
    var notes: String = ""
}
