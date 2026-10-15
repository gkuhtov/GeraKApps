import SwiftUI

public struct MuseumArtifact: Identifiable {
    public let id: String
    public let title: String
    public let category: String
    public let emoji: String
    public let isUnlocked: Bool
    public let destructionDate: String?
    public let description: String
    public let professorVerdict: String
    public let accentColor: Color

    public init(
        id: String,
        title: String,
        category: String,
        emoji: String,
        isUnlocked: Bool,
        destructionDate: String? = nil,
        description: String,
        professorVerdict: String,
        accentColor: Color = LabTheme.toxicGreen
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.emoji = emoji
        self.isUnlocked = isUnlocked
        self.destructionDate = destructionDate
        self.description = description
        self.professorVerdict = professorVerdict
        self.accentColor = accentColor
    }
}

@Observable
public final class MuseumManager {
    public static let shared = MuseumManager()

    public var artifacts: [MuseumArtifact] = [
        MuseumArtifact(
            id: "blown_speaker",
            title: "Лопнувший динамик",
            category: "Акустика",
            emoji: "🔊",
            isUnlocked: true,
            destructionDate: "27.09.2026",
            description: "Мембрана нижнего динамика не выдержала 44 кГц басового удара.",
            professorVerdict: "Хрипит как старый дед на морозе. Гордись, лаборант.",
            accentColor: LabTheme.alertRed
        ),
        MuseumArtifact(
            id: "fried_mic",
            title: "Оглушённый микрофон",
            category: "Сенсоры",
            emoji: "🎙️",
            isUnlocked: true,
            destructionDate: "28.09.2026",
            description: "Капсюль залит слюнями и перегружен воплем на 110 дБ.",
            professorVerdict: "Туда даже шептать противно. Зато тест пройден.",
            accentColor: LabTheme.hazardOrange
        ),
        MuseumArtifact(
            id: "shattered_taptic",
            title: "Расшатанный Taptic",
            category: "Механика",
            emoji: "⚡",
            isUnlocked: true,
            destructionDate: "25.09.2026",
            description: "Магнитный маятник сорвался с катушек при тесте 'Сейсмо-разнос'.",
            professorVerdict: "Вибрирует теперь как контуженый шмель.",
            accentColor: LabTheme.cyanBeam
        ),
        MuseumArtifact(
            id: "blind_lidar",
            title: "Ослепший LiDAR",
            category: "Оптика",
            emoji: "👁️",
            isUnlocked: false,
            description: "Лазерная матрица перегружена отражением в зеркальной комнате.",
            professorVerdict: "Экспонат ещё не сломан. Иди и доломай!",
            accentColor: LabTheme.toxicGreen
        ),
        MuseumArtifact(
            id: "melted_screen",
            title: "Выгоревший OLED",
            category: "Дисплей",
            emoji: "📺",
            isUnlocked: false,
            description: "Пиксели застряли на статичном белом шуме при максимальной яркости.",
            professorVerdict: "Ждёт своего идиота.",
            accentColor: LabTheme.hazardOrange
        ),
        MuseumArtifact(
            id: "frozen_battery",
            title: "Вздувшийся аккум",
            category: "Питание",
            emoji: "🔋",
            isUnlocked: false,
            description: "Литий-ионный пакет получил микротравму от циклов разряда.",
            professorVerdict: "Пока целый. Непорядок.",
            accentColor: LabTheme.alertRed
        )
    ]

    public var unlockedCount: Int {
        artifacts.filter { $0.isUnlocked }.count
    }

    public var totalCount: Int {
        artifacts.count
    }

    private init() {}
}
