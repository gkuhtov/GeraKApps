import SwiftUI

public struct DisasterLogItem: Identifiable {
    public let id: String
    public let title: String
    public let timestamp: String
    public let emoji: String
    public let damageReport: String
    public let professorVerdict: String
    public let severityColor: Color

    public init(id: String, title: String, timestamp: String, emoji: String, damageReport: String, professorVerdict: String, severityColor: Color) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.emoji = emoji
        self.damageReport = damageReport
        self.professorVerdict = professorVerdict
        self.severityColor = severityColor
    }
}

public struct HistoryView: View {
    private let personality = PersonalityEngine.shared
    private let history = HistoryManager.shared

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Шапка
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🕘 КАРТА КАТАСТРОФ")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(LabTheme.alertRed)
                            .tracking(2)
                        Text("Журнал позора")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        history.clearAll()
                        personality.say("Стёр историю? Думаешь, я забыл, как ты тут позорился? Хуй там!", emotion: .aggressive)
                    } label: {
                        Text("СМЫТЬ ГРЕХИ")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(LabTheme.alertRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(LabTheme.alertRed.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 54)

                // 📱 Интерактивный макет «ушатанного» iPhone
                damagedIPhoneWidget

                // Заголовок ленты
                Text("ПОСЛЕДНИЕ АВАРИИ")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)

                // Лента катастроф
                if history.logs.isEmpty {
                    VStack(spacing: 8) {
                        Text("📭")
                            .font(.system(size: 40))
                        Text("Журнал чист, лаборант труслив")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Запусти хоть что-нибудь, чтобы было за что стыдиться.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .liquidGlass(cornerRadius: 22, borderOpacity: 0.2)
                } else {
                    VStack(spacing: 14) {
                        ForEach(history.logs) { log in
                            disasterCard(for: log)
                        }
                    }
                }

                Spacer().frame(height: 110)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Макет «Ушатанного» iPhone
    private var damagedIPhoneWidget: some View {
        VStack(spacing: 14) {
            HStack {
                Text("СИСТЕМНЫЙ УРОН")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.hazardOrange)
                Spacer()
                Text("УРОВЕНЬ ДЕБИЛИЗМА: \(history.labStupidityScore)%")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(history.labStupidityScore > 80 ? LabTheme.alertRed : LabTheme.toxicGreen)
            }

            // Корпус телефона с датчиками
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 70, height: 110)
                        .background(Color.black.opacity(0.5))

                    Path { path in
                        path.move(to: CGPoint(x: 10, y: 15))
                        path.addLine(to: CGPoint(x: 45, y: 55))
                        path.addLine(to: CGPoint(x: 25, y: 85))
                        path.addLine(to: CGPoint(x: 60, y: 105))
                    }
                    .stroke(LabTheme.alertRed.opacity(0.8), lineWidth: 1.5)

                    Text("⚡")
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 8) {
                    sensorStatusRow(name: "Микрофон", status: "Критический износ", color: LabTheme.alertRed)
                    sensorStatusRow(name: "Taptic Engine", status: "Устал вибрировать", color: LabTheme.hazardOrange)
                    sensorStatusRow(name: "Процессор A-Series", status: "Раскалён докрасна", color: LabTheme.alertRed)
                    sensorStatusRow(name: "Динамики", status: "Хрипят от басов", color: LabTheme.cyanBeam)
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 24, borderOpacity: 0.35)
    }

    private func sensorStatusRow(name: String, status: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text(status)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
    }

    // MARK: - Карточка катастрофы
    private func disasterCard(for log: DisasterLogItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(log.emoji)
                    .font(.system(size: 26))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(log.timestamp)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text("FAIL")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(log.severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(log.severityColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text("⚠️ \(log.damageReport)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(log.severityColor)

            HStack(alignment: .top, spacing: 6) {
                Text("🧑‍🔬")
                    .font(.system(size: 12))
                Text(log.professorVerdict)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.25)
    }
}
