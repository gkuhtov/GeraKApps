import Foundation

public enum TabItem: String, CaseIterable, Identifiable {
    case home = "Главная"
    case lab = "Лаборатория"
    case random = "Случайное"
    case favorites = "Избранное"
    case history = "История"

    public var id: String { self.rawValue }

    public var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .lab: return "flask.fill"
        case .random: return "dice.fill"
        case .favorites: return "star.fill"
        case .history: return "clock.fill"
        }
    }
}
