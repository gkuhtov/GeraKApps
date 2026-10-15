import SwiftUI

public struct WorkbenchView: View {
    @Environment(\.dismiss) private var dismiss
    public var onLaunchCustomExperiment: (ExperimentItem) -> Void

    private let personality = PersonalityEngine.shared

    @State private var selectedSensor: String = "Микрофон"
    @State private var explosionDelay: Double = 5.0
    @State private var triggerDecibels: Double = 80.0
    @State private var toxicityLevel: Double = 90.0

    private let sensors = [
        ("Микрофон", "🎙️", LabTheme.hazardOrange),
        ("Taptic Engine", "⚡", LabTheme.cyanBeam),
        ("Вспышка", "🔦", LabTheme.toxicGreen),
        ("Гироскоп", "🧭", LabTheme.alertRed),
        ("Камера", "📸", LabTheme.cyanBeam)
    ]

    public init(onLaunchCustomExperiment: @escaping (ExperimentItem) -> Void = { _ in }) {
        self.onLaunchCustomExperiment = onLaunchCustomExperiment
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Шапка верстака
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🛠️ ВЕРСТАК БЕЗУМИЯ")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.hazardOrange)
                                .tracking(2)
                            Text("Собрать свой пиздец")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 24)

                    // 1. Выбор датчика
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. КАКОЙ ДАТЧИК НАСИЛУЕМ?")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(sensors, id: \.0) { item in
                                    Button {
                                        selectedSensor = item.0
                                        personality.say("Выбрал \(item.0)? Ну посмотрим, выдержит ли железо.", emotion: .mocking)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(item.1)
                                            Text(item.0)
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundColor(selectedSensor == item.0 ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedSensor == item.0 ? LabTheme.toxicGreen : Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)

                    // 2. Таймер до взрыва
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ТАЙМЕР ДО ВЗРЫВА")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("\(Int(explosionDelay)) сек")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.hazardOrange)
                        }

                        Slider(value: $explosionDelay, in: 2...15, step: 1)
                            .tint(LabTheme.hazardOrange)
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)

                    // 3. Порог срабатывания
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ПОРОГ СРАБАТЫВАНИЯ (ДБ / СИЛА)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("\(Int(triggerDecibels)) дБ")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.cyanBeam)
                        }

                        Slider(value: $triggerDecibels, in: 40...110, step: 5)
                            .tint(LabTheme.cyanBeam)
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)

                    // 4. Градус мата и токсичности
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("ГРАДУС МАТА И ТОКСИЧНОСТИ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("\(Int(toxicityLevel))%")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.alertRed)
                        }

                        Slider(value: $toxicityLevel, in: 10...100, step: 10)
                            .tint(LabTheme.alertRed)
                    }
                    .padding(16)
                    .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)

                    // Кнопка запуска
                    Button {
                        launchCustomCraft()
                    } label: {
                        HStack {
                            Spacer()
                            Text("💥 ЗАПУСТИТЬ КАСТОМНЫЙ РАЗЪЁБ")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(LabTheme.toxicGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func launchCustomCraft() {
        let currentEmoji = sensors.first(where: { $0.0 == selectedSensor })?.1 ?? "🧪"
        let customExp = ExperimentItem(
            id: "custom_\(UUID().uuidString.prefix(6))",
            title: "Кастом: \(selectedSensor)",
            subtitle: "Таймер \(Int(explosionDelay))с • Порог \(Int(triggerDecibels)) дБ",
            emoji: currentEmoji,
            requiredHardware: selectedSensor,
            accentColor: LabTheme.hazardOrange
        )

        personality.say("Конфиг собран! Держи телефон крепче, щас бахнет!", emotion: .panic)
        dismiss()
        onLaunchCustomExperiment(customExp)
    }
}
