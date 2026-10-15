import SwiftUI

public struct PrivateExperiment: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let emoji: String
    public let dangerLevel: String
    public let requiredHardware: String
    public let accentColor: Color

    public func toExperimentItem() -> ExperimentItem {
        ExperimentItem(
            id: id,
            title: title,
            subtitle: subtitle,
            emoji: emoji,
            requiredHardware: requiredHardware,
            accentColor: accentColor
        )
    }
}

public struct PrivateLabView: View {
    @Environment(\.dismiss) private var dismiss
    private let personality = PersonalityEngine.shared

    @State private var activeExperiment: ExperimentItem?
    @State private var pulseGlow: Bool = false

    private let privateExperiments = [
        PrivateExperiment(
            id: "whisper_detector",
            title: "Детектор интимного шёпота",
            subtitle: "Сверхчувствительный замер дыхания и стонов (10–35 дБ)",
            emoji: "🤫",
            dangerLevel: "КРИТИЧЕСКИЙ",
            requiredHardware: "Студийный микрофон",
            accentColor: LabTheme.alertRed
        ),
        PrivateExperiment(
            id: "tachycardia_test",
            title: "Тахикардия на грани",
            subtitle: "Анализ пульса через вспышку камеры на пределе паники",
            emoji: "💓",
            dangerLevel: "ВЫСОКИЙ",
            requiredHardware: "Вспышка + Фотодиод",
            accentColor: LabTheme.hazardOrange
        ),
        PrivateExperiment(
            id: "taptic_sapper",
            title: "Тактильный сапёр",
            subtitle: "Поиск детонатора по микро-ударам Taptic. Дрогнул палец — взрыв",
            emoji: "🧨",
            dangerLevel: "ЭКСТРИМ",
            requiredHardware: "Taptic Engine",
            accentColor: LabTheme.cyanBeam
        )
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Фоновое тревожное свечение
            Circle()
                .fill(LabTheme.alertRed.opacity(pulseGlow ? 0.22 : 0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: pulseGlow)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Шапка аварийного протокола
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("☣️")
                                Text("ЗАСЕКРЕЧЕННЫЙ ПРОТОКОЛ")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(LabTheme.alertRed)
                                    .tracking(2)
                            }
                            Text("Private Lab 18+")
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Кнопка экстренной эвакуации
                        Button {
                            personality.say("Эвакуация выполнена. Следы подтёрты.", emotion: .whisper)
                            dismiss()
                        } label: {
                            Text("СВАЛИТЬ")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(LabTheme.alertRed)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 40)

                    // Предупреждение
                    HStack(spacing: 12) {
                        Text("⚠️")
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ОТКЛЮЧЕНЫ ВСЕ ОГРАНИЧИТЕЛИ БЕЗОПАСНОСТИ")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(LabTheme.alertRed)
                            Text("Опыты в этом отсеке используют датчики на пределе возможностей железа.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }
                    .padding(14)
                    .background(LabTheme.alertRed.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LabTheme.alertRed.opacity(0.4), lineWidth: 1)
                    )

                    // Список запретных опытов
                    VStack(spacing: 14) {
                        ForEach(privateExperiments) { exp in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 14) {
                                    Text(exp.emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 52, height: 52)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(exp.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)

                                        Text(exp.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.6))
                                    }

                                    Spacer()
                                }

                                HStack {
                                    Text("УРОВЕНЬ: \(exp.dangerLevel)")
                                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                        .foregroundColor(exp.accentColor)

                                    Spacer()

                                    Button {
                                        personality.say("Ты уверен? Ну смотри, назад пути не будет.", emotion: .whisper)
                                        activeExperiment = exp.toExperimentItem()
                                    } label: {
                                        Text("ТЕСТ")
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 7)
                                            .background(exp.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 22, borderOpacity: 0.35)
                        }
                    }

                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            pulseGlow = true
        }
        .fullScreenCover(item: $activeExperiment) { item in
            ExperimentExecutionView(experiment: item)
        }
    }
}
