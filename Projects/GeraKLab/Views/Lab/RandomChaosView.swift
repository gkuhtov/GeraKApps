import SwiftUI

public struct RandomChaosView: View {
    @Binding public var isPresented: Bool
    public var onLaunchChaosExperiment: (ExperimentItem) -> Void

    @State private var objectIndex: Int = 0
    @State private var actionIndex: Int = 0
    @State private var conditionIndex: Int = 0

    @State private var isSpinning: Bool = true
    @State private var countdown: Int = 3
    @State private var isCountdownActive: Bool = false

    private let personality = PersonalityEngine.shared

    private let objects = [
        ("🎙️", "Микрофон"),
        ("⚡", "Гироскоп"),
        ("🔦", "Вспышка"),
        ("📺", "Матрица экрана"),
        ("📸", "Камера лица")
    ]

    private let actions = [
        "Аварийный разгон до 1000°C",
        "Ультразвуковой замер крика",
        "Тест на сотрясение процессора",
        "Слеповой стробоскоп",
        "Детектор дикого пиздежа"
    ]

    private let conditions = [
        "Ори матом громче 85 дБ",
        "Тряси телефон как бешеный",
        "Не моргай 7 секунд в объектив",
        "Зажми экран всеми 5 пальцами",
        "Шепчи оскорбления прямо в ухо"
    ]

    public init(
        isPresented: Binding<Bool>,
        onLaunchChaosExperiment: @escaping (ExperimentItem) -> Void = { _ in }
    ) {
        self._isPresented = isPresented
        self.onLaunchChaosExperiment = onLaunchChaosExperiment
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 24) {
                // Шапка тревоги
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🚨 НЕОБРАТИМЫЙ СИНТЕЗ")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(LabTheme.alertRed)
                            .tracking(2)

                        Text("Случайный пиздец")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if !isSpinning && !isCountdownActive {
                        Button {
                            personality.say("Слился, лаборант? Ну и вали на главную!", emotion: .mocking)
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                Spacer()

                // Слот-машина: 3 стеклянных барабана
                VStack(spacing: 14) {
                    slotCard(
                        title: "ДАТЧИК / ЖЕЛЕЗО",
                        content: "\(objects[objectIndex].0) \(objects[objectIndex].1)",
                        color: LabTheme.cyanBeam
                    )

                    slotCard(
                        title: "ДЕЙСТВИЕ",
                        content: actions[actionIndex],
                        color: LabTheme.hazardOrange
                    )

                    slotCard(
                        title: "УСЛОВИЕ РАЗЪЁБА",
                        content: conditions[conditionIndex],
                        color: LabTheme.alertRed
                    )
                }
                .padding(.horizontal, 20)

                Spacer()

                // Блок отсчёта
                VStack(spacing: 8) {
                    if isCountdownActive {
                        VStack(spacing: 4) {
                            Text("\(countdown)")
                                .font(.system(size: 64, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.alertRed)
                                .scaleEffect(1.2)

                            Text("ПРИГОТОВИТЬСЯ К АВАРИИ!")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    } else if isSpinning {
                        Text("Синтез цепной реакции...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(height: 90)

                Spacer()
            }
        }
        .onAppear {
            startChaosRoulette()
        }
    }

    @ViewBuilder
    private func slotCard(title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .tracking(1.5)

            Text(content)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, borderOpacity: 0.35)
    }

    private func startChaosRoulette() {
        isSpinning = true
        isCountdownActive = false

        _ = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { t in
            if isSpinning {
                objectIndex = Int.random(in: 0..<objects.count)
                actionIndex = Int.random(in: 0..<actions.count)
                conditionIndex = Int.random(in: 0..<conditions.count)
            } else {
                t.invalidate()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            personality.say("Так, выпало железо... держись крепче!", emotion: .panic)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            isSpinning = false
            startCountdown()
        }
    }

    private func startCountdown() {
        isCountdownActive = true
        countdown = 3
        personality.say("Три... два... один... пошла жара!", emotion: .aggressive)

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if countdown > 1 {
                countdown -= 1
            } else {
                t.invalidate()
                isCountdownActive = false

                let finalExp = ExperimentItem(
                    id: "chaos_\(UUID().uuidString.prefix(6))",
                    title: actions[actionIndex],
                    subtitle: conditions[conditionIndex],
                    emoji: objects[objectIndex].0,
                    requiredHardware: objects[objectIndex].1,
                    accentColor: LabTheme.alertRed
                )

                isPresented = false
                onLaunchChaosExperiment(finalExp)
            }
        }
    }
}
