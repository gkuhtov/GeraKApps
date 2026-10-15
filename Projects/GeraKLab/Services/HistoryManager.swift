import SwiftUI

@Observable
public final class HistoryManager {
    public static let shared = HistoryManager()

    public var logs: [DisasterLogItem] = [
        DisasterLogItem(
            id: "log_init_1",
            title: "Аварийный разгон через микрофон",
            timestamp: "Сегодня, 04:18",
            emoji: "🎙️",
            damageReport: "Микрофон перегружен на 108 дБ",
            professorVerdict: "Орал так, будто тебя черти дерут. Динамик чуть не выплюнуло.",
            severityColor: LabTheme.alertRed
        ),
        DisasterLogItem(
            id: "log_init_2",
            title: "Сейсмо-разнос гироскопа",
            timestamp: "Вчера, 23:45",
            emoji: "⚡",
            damageReport: "Taptic Engine перегрелся на 42%",
            professorVerdict: "Тряс телефон с такой дурью, что датчик движения чуть не вышел из чата.",
            severityColor: LabTheme.hazardOrange
        )
    ]

    public var labStupidityScore: Int {
        min(99, max(12, logs.count * 18 + 24))
    }

    private init() {}

    /// Запись новой катастрофы в журнал
    public func recordDisaster(title: String, emoji: String, peakDecibels: Float, hardware: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        let timeString = "Сегодня, \(formatter.string(from: Date()))"

        let damage = peakDecibels > 85 ? "Перегрузка датчика: \(Int(peakDecibels)) дБ" : "Слабая нагрузка железа"
        let verdict = peakDecibels > 85
            ? "Чуть мембрану не порвал своими визгами. Эксперимент засчитан как авария."
            : "Вяло, лаборант. Железо даже не вспотело, переделывай."

        let newLog = DisasterLogItem(
            id: UUID().uuidString,
            title: title,
            timestamp: timeString,
            emoji: emoji,
            damageReport: damage,
            professorVerdict: verdict,
            severityColor: peakDecibels > 85 ? LabTheme.alertRed : LabTheme.hazardOrange
        )

        DispatchQueue.main.async {
            self.logs.insert(newLog, at: 0)
        }
    }

    /// Смыть все грехи
    public func clearAll() {
        logs.removeAll()
    }
}
