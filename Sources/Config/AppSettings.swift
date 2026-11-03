import AppKit
import Foundation

struct AppSettings: Codable, Equatable {
    var provider: TranslationProvider = .google
    var baseURL: String = ""
    var apiKey: String = ""
    var model: String = "openai/gpt-5-nano"
    var reasoningEffort: ReasoningEffort?
    var deepLAPIKey: String = ""
    var deepLPlan: DeepLPlan = .free
    var hotkey: KeyboardShortcut = .defaultShortcut
    var enableCtrlSpace: Bool = true
    var enableDoubleCommand: Bool = true

    init() {}

    private enum CodingKeys: String, CodingKey {
        case provider, baseURL, apiKey, model, reasoningEffort, deepLAPIKey, deepLPlan
        case hotkey, enableCtrlSpace, enableDoubleCommand
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provider = try container.decodeIfPresent(TranslationProvider.self, forKey: .provider) ?? .google
        baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? ""
        apiKey = try container.decodeIfPresent(String.self, forKey: .apiKey) ?? ""
        model = try container.decodeIfPresent(String.self, forKey: .model) ?? "openai/gpt-5-nano"
        reasoningEffort = try container.decodeIfPresent(ReasoningEffort.self, forKey: .reasoningEffort)
        deepLAPIKey = try container.decodeIfPresent(String.self, forKey: .deepLAPIKey) ?? ""
        deepLPlan = try container.decodeIfPresent(DeepLPlan.self, forKey: .deepLPlan) ?? .free
        hotkey = try container.decodeIfPresent(KeyboardShortcut.self, forKey: .hotkey) ?? .defaultShortcut
        enableCtrlSpace = try container.decodeIfPresent(Bool.self, forKey: .enableCtrlSpace) ?? true
        enableDoubleCommand = try container.decodeIfPresent(Bool.self, forKey: .enableDoubleCommand) ?? true
    }

    var hotkeyDisplay: String {
        get { hotkey.displayString }
        set {
            if let parsed = KeyboardShortcut.parse(from: newValue) {
                hotkey = parsed
            }
        }
    }
}

enum TranslationProvider: String, Codable, CaseIterable, Identifiable {
    case google
    case openAICompatible
    case deepL

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .openAICompatible:
            return "OpenAI Compatible"
        case .deepL:
            return "DeepL"
        }
    }
}

enum ReasoningEffort: String, Codable, CaseIterable, Identifiable {
    case none, minimal, low, medium, high, xhigh, max

    var id: String { rawValue }
}

enum DeepLPlan: String, Codable, CaseIterable, Identifiable {
    case free, pro

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .free: return "https://api-free.deepl.com"
        case .pro: return "https://api.deepl.com"
        }
    }
}

struct KeyboardShortcut: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: NSEvent.ModifierFlags

    static let defaultShortcut = KeyboardShortcut(
        keyCode: 49,
        modifiers: [.control]
    )

    var displayString: String {
        let modifierText: String
        if modifiers.contains(.command) && modifiers.contains(.shift) {
            modifierText = "⌘⇧"
        } else if modifiers.contains(.control) && modifiers.contains(.option) {
            modifierText = "⌃⌥"
        } else if modifiers.contains(.control) && modifiers.contains(.command) {
            modifierText = "⌃⌘"
        } else if modifiers.contains(.option) && modifiers.contains(.shift) {
            modifierText = "⌥⇧"
        } else if modifiers.contains(.control) {
            modifierText = "⌃"
        } else if modifiers.contains(.option) {
            modifierText = "⌥"
        } else {
            modifierText = ""
        }

        let keyText: String
        switch keyCode {
        case 49:
            keyText = "Space"
        case 17:
            keyText = "T"
        default:
            keyText = "KeyCode(\(keyCode))"
        }

        return modifierText + keyText
    }

    static func parse(from string: String) -> KeyboardShortcut? {
        let normalized = string.lowercased().replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "⌃space", "ctrlspace", "controlspace":
            return .defaultShortcut
        case "⌃⌥space", "ctrloptionspace", "controloptionspace":
            return KeyboardShortcut(keyCode: 49, modifiers: [.control, .option])
        case "⌘⇧space", "commandshiftspace":
            return KeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])
        case "⌃⌘t", "ctrlcommandt", "controlcommandt":
            return KeyboardShortcut(keyCode: 17, modifiers: [.control, .command])
        case "⌥⇧t", "optionshiftt":
            return KeyboardShortcut(keyCode: 17, modifiers: [.option, .shift])
        default:
            return nil
        }
    }
}

extension NSEvent.ModifierFlags: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt.self)
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
