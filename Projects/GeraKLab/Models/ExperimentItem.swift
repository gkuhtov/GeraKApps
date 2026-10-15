import SwiftUI

public struct ExperimentItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let emoji: String
    public let dangerLevel: Int
    public let requiredHardware: String
    public let hexColor: String
    public var mechanic: String?
    public var runCount: Int
    public var isFavorite: Bool

    public var accentColor: Color {
        let cleanHex = hexColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return LabTheme.cyanBeam
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    public var resolvedMechanic: String {
        if let m = mechanic, !m.isEmpty { return m }
        let hw = requiredHardware.lowercased()
        if hw.contains("гироскоп") { return "core_balance" }
        if hw.contains("акселерометр") { return "shake_gforce" }
        if hw.contains("вспышка") || hw.contains("камера") { return "strobe_touch" }
        if hw.contains("приближения") { return "proximity_facepalm" }
        return "audio_scream"
    }

    // Основной инициализатор
    public init(
        id: String,
        title: String,
        description: String = "",
        emoji: String = "⚡",
        dangerLevel: Int = 3,
        requiredHardware: String = "Датчик",
        hexColor: String = "#00F0FF",
        mechanic: String? = nil,
        runCount: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.dangerLevel = dangerLevel
        self.requiredHardware = requiredHardware
        self.hexColor = hexColor
        self.mechanic = mechanic
        self.runCount = runCount
        self.isFavorite = isFavorite
    }

    // Совместимый инициализатор для старого кода (с subtitle и accentColor)
    public init(
        id: String,
        title: String,
        subtitle: String = "",
        emoji: String = "⚡",
        requiredHardware: String = "Датчик",
        accentColor: Color = LabTheme.cyanBeam,
        dangerLevel: Int = 3,
        mechanic: String? = nil,
        runCount: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = subtitle
        self.emoji = emoji
        self.dangerLevel = dangerLevel
        self.requiredHardware = requiredHardware
        self.hexColor = "#00F0FF"
        self.mechanic = mechanic
        self.runCount = runCount
        self.isFavorite = isFavorite
    }
}
