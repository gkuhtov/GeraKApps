import SwiftUI

public struct ExperimentExecutionView: View {
    public let experiment: ExperimentItem
    @Environment(\.dismiss) private var dismiss

    private let sensor = SensorEngine.shared
    private let motion = MotionEngine.shared
    private let strobe = FlashlightEngine.shared
    private let personality = PersonalityEngine.shared
    private let history = HistoryManager.shared

    // Состояния сессии
    @State private var isFinished: Bool = false
    @State private var hasFailed: Bool = false
    @State private var failureReason: String = ""
    @State private var gameLoopTimer: Timer?
    @State private var totalTimeElapsed: Double = 0.0

    // Прогресс 0.0 ... 1.0
    @State private var gameProgress: Double = 0.0

    // Физика ядра (core_balance)
    @State private var ballPosition: CGPoint = .zero
    @State private var ballVelocity: CGPoint = .zero

    // Светофор (red_light_green_light)
    @State private var isRedPhase: Bool = false
    @State private var nextPhaseSwitch: Double = 1.8

    // Тапы и вспышка (strobe_touch)
    @State private var tapHits: Int = 0
    @State private var strobeScreenFlash: Bool = false

    // Датчик приближения (proximity_facepalm)
    @State private var proximityContactSeconds: Double = 0.0

    public init(experiment: ExperimentItem) {
        self.experiment = experiment
    }

    public var body: some View {
        ZStack {
            if hasFailed {
                LabTheme.alertRed.opacity(0.85).ignoresSafeArea()
            } else if experiment.resolvedMechanic == "red_light_green_light" && isRedPhase {
                Color.red.opacity(0.8).ignoresSafeArea()
            } else if experiment.resolvedMechanic == "strobe_touch" && strobeScreenFlash {
                Color.white.ignoresSafeArea()
            } else {
                Color.black.opacity(0.96).ignoresSafeArea()
            }

            VStack(spacing: 20) {
                // Шапка
                headerBar
                    .padding(.horizontal, 22)
                    .padding(.top, 24)

                Spacer()

                // Центральная игровая зона
                arenaView

                Spacer()

                // Нижний HUD
                bottomHudView
                    .padding(.horizontal, 20)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    handleScreenTap()
                }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                startGameplay()
            }
        }
        .onDisappear {
            stopEngines()
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hudSubtitle.uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(isRedPhase ? .white : experiment.accentColor)
                    .tracking(2)
                Text(experiment.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                stopEngines()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    private var hudSubtitle: String {
        if hasFailed { return "💀 ФАТАЛЬНЫЙ СБОЙ" }
        if isFinished { return "🏆 ИСПЫТАНИЕ ПРОЙДЕНО" }
        switch experiment.resolvedMechanic {
        case "nitro_freeze": return "🧪 НЕ ДЫШАТЬ И НЕ ДВИГАТЬСЯ"
        case "red_light_green_light": return isRedPhase ? "🛑 ЗАМРИ НАХУЙ!" : "🟢 ТРЯСИ СО ВСЕЙ ДУРИ!"
        case "core_balance": return "☢️ УДЕРЖИВАЙ ЯДРО В ПРИЦЕЛЕ"
        case "strobe_touch": return "🔨 ДОЛБИ ДВУМЯ ПАЛЬЦАМИ!"
        case "proximity_facepalm": return "🧠 ПРИЖМИ К ТЕЛУ ИЛИ ЛБУ"
        default: return "🎯 ДЕРЖИ ЗВУК В ЗЕЛЕНОЙ ЗОНЕ"
        }
    }

    @ViewBuilder
    private var arenaView: some View {
        ZStack {
            Circle()
                .stroke(isRedPhase ? Color.white : experiment.accentColor.opacity(0.35), lineWidth: 3)
                .frame(width: 170, height: 170)

            switch experiment.resolvedMechanic {
            case "nitro_freeze":
                nitroView
            case "red_light_green_light":
                trafficView
            case "core_balance":
                physicsCoreView
            case "strobe_touch":
                strobeTapView
            case "proximity_facepalm":
                proximityFaceView
            default:
                audioCorridorView
            }
        }
        .frame(width: 170, height: 170)
        .liquidGlass(cornerRadius: 85, borderOpacity: 0.35)
    }

    private var nitroView: some View {
        VStack(spacing: 8) {
            Text(hasFailed ? "💥" : "🧪")
                .font(.system(size: 64))
                .scaleEffect(hasFailed ? 1.4 : 1.0)
            if !hasFailed && !isFinished {
                Text("\(Int(gameProgress * 100))%")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.toxicGreen)
            }
        }
    }

    private var trafficView: some View {
        VStack(spacing: 6) {
            Text(isRedPhase ? "🛑" : "🟢")
                .font(.system(size: 68))
                .scaleEffect(isRedPhase ? 1.15 : 1.0)
            Text(isRedPhase ? "СТОЙ!" : "ТРЯСИ!")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private var physicsCoreView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 120, height: 120)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [LabTheme.cyanBeam, LabTheme.toxicGreen],
                        center: .center,
                        startRadius: 2,
                        endRadius: 14
                    )
                )
                .frame(width: 26, height: 26)
                .shadow(color: LabTheme.cyanBeam, radius: 10)
                .offset(x: ballPosition.x, y: ballPosition.y)
        }
    }

    private var strobeTapView: some View {
        VStack(spacing: 6) {
            Text("🖐️")
                .font(.system(size: 58))
                .scaleEffect(max(0.85, 1.0 - CGFloat(tapHits) * 0.005))
            Text("\(tapHits) ТАПОВ")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(LabTheme.toxicGreen)
        }
    }

    private var proximityFaceView: some View {
        VStack(spacing: 6) {
            Text(UIDevice.current.proximityState ? "🧠" : "🤦‍♂️")
                .font(.system(size: 62))
            Text(UIDevice.current.proximityState ? "ОХЛАЖДЕНИЕ..." : "ПРИЖМИ К ЛБУ!")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(UIDevice.current.proximityState ? LabTheme.toxicGreen : LabTheme.hazardOrange)
        }
    }

    private var audioCorridorView: some View {
        VStack(spacing: 8) {
            Text(experiment.emoji)
                .font(.system(size: 56))
                .scaleEffect(1.0 + CGFloat(sensor.currentDecibels) / 260.0)

            Text("\(Int(sensor.currentDecibels)) дБ")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundColor(isAudioInTargetRange ? LabTheme.toxicGreen : LabTheme.hazardOrange)
        }
    }

    private var isAudioInTargetRange: Bool {
        sensor.currentDecibels >= 60 && sensor.currentDecibels <= 80
    }

    private var bottomHudView: some View {
        VStack(spacing: 12) {
            if hasFailed {
                VStack(spacing: 4) {
                    Text("💥 ПРОВАЛ!")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(LabTheme.alertRed)
                    Text(failureReason)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            } else if isFinished {
                VStack(spacing: 4) {
                    Text("🎉 ТЕСТ ВЫПОЛНЕН!")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(LabTheme.toxicGreen)
                    Text("Железо выжило. Результат внесён в архив катастроф.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("ПРОГРЕСС РАЗГОНА")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(gameProgress * 100))%")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(LabTheme.cyanBeam)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.12))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [LabTheme.cyanBeam, LabTheme.toxicGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(min(1.0, max(0.02, gameProgress))))
                        }
                    }
                    .frame(height: 10)

                    Text(instructionText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
    }

    private var instructionText: String {
        switch experiment.resolvedMechanic {
        case "nitro_freeze": return "Держи телефон абсолютно неподвижно и тихо 5 секунд"
        case "red_light_green_light": return "Тряси на зелёный свет! При смене на красный — мгновенно замри!"
        case "core_balance": return "Наклоняй корпус телефона, удерживай шар ближе к центру"
        case "strobe_touch": return "Тапай двумя пальцами как из пулемёта, опережай падение шкалы!"
        case "proximity_facepalm": return "Держи экран плотно прижатым ко лбу или руке"
        default: return "Гуди или говори в микрофон ровно в диапазоне 60-80 дБ"
        }
    }

    private func handleScreenTap() {
        guard !isFinished && !hasFailed else { return }
        if experiment.resolvedMechanic == "strobe_touch" {
            tapHits += 1
            gameProgress = min(1.0, gameProgress + 0.038)
            sensor.triggerClick()
            if gameProgress >= 1.0 {
                completeGame(success: true)
            }
        }
    }

    private func startGameplay() {
        isFinished = false
        hasFailed = false
        failureReason = ""
        gameProgress = 0.0
        totalTimeElapsed = 0.0
        ballPosition = .zero
        ballVelocity = .zero
        tapHits = 0
        proximityContactSeconds = 0.0

        switch experiment.resolvedMechanic {
        case "nitro_freeze":
            personality.say("Нитроглицерин! Замри, блять, и не дыши вообще!", emotion: .whisper)
            sensor.startAudioMetering()
            motion.startTracking()
        case "red_light_green_light":
            isRedPhase = false
            nextPhaseSwitch = 1.6
            personality.say("Зелёный свет! Тряси со всей дури!", emotion: .aggressive)
            motion.startTracking()
        case "core_balance":
            personality.say("Удерживай ядро реактора! Наклоняй телефон и держи центр!", emotion: .panic)
            motion.startTracking()
        case "strobe_touch":
            personality.say("Вспышка стробит! Долби по экрану двумя пальцами!", emotion: .aggressive)
            strobe.startStrobe(interval: 0.07)
        case "proximity_facepalm":
            personality.say("Приложи экран ко лбу! Охлаждаем твои две извилины!", emotion: .mocking)
            UIDevice.current.isProximityMonitoringEnabled = true
        default:
            personality.say("Держи звук строго в зеленом секторе! Не переори!", emotion: .aggressive)
            sensor.startAudioMetering()
        }

        gameLoopTimer?.invalidate()
        gameLoopTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            guard !isFinished && !hasFailed else { return }
            self.tickSimulation(dt: 0.033)
        }
    }

    private func tickSimulation(dt: Double) {
        totalTimeElapsed += dt

        switch experiment.resolvedMechanic {
        case "nitro_freeze":
            if motion.currentGForce > 1.18 {
                failGame(reason: "Руки трясутся! Ты взорвал колбу нитроглицерина.")
                return
            }
            if sensor.currentDecibels > 62 {
                failGame(reason: "Ты слишком громко сопел! Взрыв от акустического хлопка.")
                return
            }
            gameProgress += dt / 5.0
            if gameProgress >= 1.0 {
                completeGame(success: true)
            }

        case "red_light_green_light":
            if totalTimeElapsed >= nextPhaseSwitch {
                isRedPhase.toggle()
                totalTimeElapsed = 0.0
                nextPhaseSwitch = isRedPhase ? Double.random(in: 1.4...2.2) : Double.random(in: 1.8...2.8)
                sensor.triggerClick()
                if isRedPhase {
                    personality.say("СТОЯТЬ, СУКА!", emotion: .aggressive)
                }
            }

            if isRedPhase {
                if motion.currentGForce > 1.14 {
                    failGame(reason: "РАЗРЫВ СЕРДЦА! Ты пошевелился на красный свет.")
                    return
                }
            } else {
                if motion.currentGForce > 1.4 {
                    gameProgress += (motion.currentGForce - 1.0) * 0.012
                }
            }

            if gameProgress >= 1.0 {
                completeGame(success: true)
            }

        case "core_balance":
            let ax = motion.roll * 420.0
            let ay = motion.pitch * 420.0
            ballVelocity.x = (ballVelocity.x + ax * dt) * 0.94
            ballVelocity.y = (ballVelocity.y + ay * dt) * 0.94
            ballPosition.x += ballVelocity.x * dt
            ballPosition.y += ballVelocity.y * dt

            let dist = sqrt(pow(ballPosition.x, 2) + pow(ballPosition.y, 2))
            if dist > 68.0 {
                failGame(reason: "Разгерметизация! Шар вылетел за пределы магнитной ловушки.")
                return
            }

            if dist < 40.0 {
                gameProgress += dt / 6.0
            } else {
                gameProgress = max(0.0, gameProgress - dt * 0.1)
            }

            if gameProgress >= 1.0 {
                completeGame(success: true)
            }

        case "strobe_touch":
            strobeScreenFlash.toggle()
            gameProgress = max(0.0, gameProgress - dt * 0.14)

        case "proximity_facepalm":
            if UIDevice.current.proximityState {
                proximityContactSeconds += dt
                gameProgress = min(1.0, proximityContactSeconds / 3.0)
                if gameProgress >= 1.0 {
                    completeGame(success: true)
                }
            } else {
                if proximityContactSeconds > 0.3 {
                    failGame(reason: "Рано оторвал от лба! Контакт прерван, мозг не охладился.")
                    return
                }
            }

        default:
            if isAudioInTargetRange {
                gameProgress += dt / 4.0
            } else if sensor.currentDecibels > 82 {
                failGame(reason: "Слишком громко! Мембрана микрофона раскалилась и треснула.")
                return
            } else {
                gameProgress = max(0.0, gameProgress - dt * 0.1)
            }

            if gameProgress >= 1.0 {
                completeGame(success: true)
            }
        }
    }

    private func failGame(reason: String) {
        hasFailed = true
        isFinished = true
        failureReason = reason
        stopEngines()
        sensor.triggerExplosionHaptics()
        personality.say(reason, emotion: .aggressive)
    }

    private func completeGame(success: Bool) {
        isFinished = true
        hasFailed = false
        gameProgress = 1.0
        stopEngines()
        sensor.triggerExplosionHaptics()

        history.recordDisaster(
            title: experiment.title,
            emoji: experiment.emoji,
            peakDecibels: Float(sensor.currentDecibels),
            hardware: experiment.requiredHardware
        )

        personality.say("Опыт сдан! Железо чудом уцелело под твоими руками.", emotion: .mocking)
    }

    private func stopEngines() {
        gameLoopTimer?.invalidate()
        gameLoopTimer = nil
        sensor.stopAudioMetering()
        motion.stopTracking()
        strobe.stopStrobe()
        strobeScreenFlash = false
        UIDevice.current.isProximityMonitoringEnabled = false
    }
}
