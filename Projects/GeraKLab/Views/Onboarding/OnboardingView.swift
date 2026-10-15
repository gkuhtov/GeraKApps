import SwiftUI
import AVFoundation
import UserNotifications

public struct OnboardingView: View {
    @Binding public var isCompleted: Bool

    @State private var step: Int = 1
    @State private var micGranted: Bool = false
    @State private var cameraGranted: Bool = false
    @State private var pushGranted: Bool = false

    // Калибровка криком (шаг 3)
    @State private var calibrationPassed: Bool = false
    @State private var peakShout: Float = 0.0
    private let sensor = SensorEngine.shared

    public init(isCompleted: Binding<Bool>) {
        self._isCompleted = isCompleted
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Прогресс-бар шагов
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { index in
                        Capsule()
                            .fill(step >= index ? LabTheme.toxicGreen : Color.white.opacity(0.15))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Контент шагов
                Group {
                    switch step {
                    case 1:
                        waiverStepView
                    case 2:
                        permissionsStepView
                    case 3:
                        calibrationStepView
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
        }
        .onAppear {
            checkCurrentPermissions()
        }
    }

    // MARK: - ШАГ 1: Акт об отказе от претензий
    private var waiverStepView: some View {
        VStack(spacing: 20) {
            Text("⚠️")
                .font(.system(size: 64))

            VStack(spacing: 6) {
                Text("ПРОТОКОЛ ВХОДНОГО КОНТРОЛЯ")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.alertRed)
                    .tracking(2)

                Text("Ты кто такой вообще?")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Стоять, блять. Руки от экрана убрал и слушай сюда.")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(LabTheme.hazardOrange)

                Text("Это тебе не очередной ублюдский кликер и не галерея обоев. Здесь мы насилуем железо до визга катушек и греем процессор так, что клей под дисплеем поплывёт.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))

                Text("Если у тебя сдохнет Taptic Engine, лопнет мембрана динамика или вздуется аккумулятор — Apple пошлёт тебя нахуй, а я скажу, что впервые тебя вижу.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))

                Text("Обосрался? Сноси прямо сейчас. Если остаёшься — подтверждай.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LabTheme.alertRed)
            }
            .padding(18)
            .liquidGlass(cornerRadius: 22, borderOpacity: 0.35)
            .padding(.horizontal, 20)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = 2
                }
            } label: {
                HStack {
                    Spacer()
                    Text("ПОДТВЕРЖДАЮ, МНЕ ПОХУЙ НА ГАРАНТИЮ")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(LabTheme.alertRed)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Text("(Нажимая, вы соглашаетесь на износ компонентов и регулярные оскорбления)")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    // MARK: - ШАГ 2: Выбиватель системных разрешений
    private var permissionsStepView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("СИСТЕМНЫЙ РЭКЕТ")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.hazardOrange)
                    .tracking(2)

                Text("Гони доступы к датчикам")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                // 1. Микрофон
                permissionCard(
                    title: "МИКРОФОН",
                    speech: "Будешь орать во всю глотку на децибелы. Шептать будешь у мамки на кухне. Не дашь микрофон — сиди смотри в стену.",
                    buttonTitle: micGranted ? "МИКРОФОН ВЗЯТ С БОЕМ" : "ОТКРЫТЬ ЕБАЛО И ДАТЬ ДОСТУП",
                    isGranted: micGranted,
                    color: LabTheme.alertRed
                ) {
                    requestMicrophone()
                }

                // 2. Камера и вспышка
                permissionCard(
                    title: "КАМЕРА И ВСПЫШКА",
                    speech: "Рожа твоя нахуй не сдалась. Вспышка пойдёт на стробоскоп, а объектив — мерить пульс, пока ты дрожишь от страха.",
                    buttonTitle: cameraGranted ? "ОПТИКА ЗАХВАЧЕНА" : "ВЫЖЕЧЬ СЕТЧАТКУ СТРОБОСКОПОМ",
                    isGranted: cameraGranted,
                    color: LabTheme.hazardOrange
                ) {
                    requestCamera()
                }

                // 3. Пуши и Taptic
                permissionCard(
                    title: "ПУШИ И УВЕДОМЛЕНИЯ",
                    speech: "Буду слать тебе тревоги посреди ночи, если забьёшь хуй на испытания, и долбить виброй до звона в ушах.",
                    buttonTitle: pushGranted ? "КАНАЛ СВЯЗИ ОТКРЫТ" : "РАЗРЕШАЮ ЕБАТЬ МОЗГИ ПУШАМИ",
                    isGranted: pushGranted,
                    color: LabTheme.cyanBeam
                ) {
                    requestPush()
                }
            }
            .padding(.horizontal, 20)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = 3
                }
            } label: {
                HStack {
                    Spacer()
                    Text("ПЕРЕЙТИ К ПРИСЯГЕ")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.vertical, 15)
                .background(LabTheme.toxicGreen)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
    }

    private func permissionCard(
        title: String,
        speech: String,
        buttonTitle: String,
        isGranted: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                Spacer()
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(LabTheme.toxicGreen)
                }
            }

            Text(speech)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(isGranted ? LabTheme.toxicGreen : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isGranted ? LabTheme.toxicGreen.opacity(0.12) : color.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isGranted ? LabTheme.toxicGreen.opacity(0.4) : color, lineWidth: 1)
                    )
            }
            .disabled(isGranted)
        }
        .padding(12)
        .liquidGlass(cornerRadius: 18, borderOpacity: 0.25)
    }

    // MARK: - ШАГ 3: Калибровочная затрещина
    private var calibrationStepView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("БОЕВОЕ КРЕЩЕНИЕ")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.alertRed)
                    .tracking(2)

                Text("Проверка связок лаборанта")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
            }

            VStack(spacing: 16) {
                Text(calibrationPassed ? "💥" : "🎙️")
                    .font(.system(size: 64))
                    .frame(width: 110, height: 110)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(calibrationPassed ? LabTheme.toxicGreen : LabTheme.alertRed, lineWidth: 3)
                            .scaleEffect(1.0 + CGFloat(sensor.currentDecibels) / 250.0)
                    )

                VStack(spacing: 6) {
                    Text(calibrationPassed ? "КАЛИБРОВКА ПРОЙДЕНА!" : "РЯВКНИ В МИКРОФОН ПРЯМО СЕЙЧАС!")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(calibrationPassed ? LabTheme.toxicGreen : LabTheme.hazardOrange)

                    Text(calibrationPassed ? "Пик: \(Int(peakShout)) дБ. Голосок слабоват, но сойдёт." : "Выдай громче 75 дБ, чтобы активировать системы")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
            .padding(.horizontal, 20)

            Button {
                sensor.stopAudioMetering()
                PersonalityEngine.shared.say("Лаборатория открыта. Пиздуй работать, лаборант!", emotion: .aggressive)
                isCompleted = true
            } label: {
                HStack {
                    Spacer()
                    Text("ВОЙТИ В ЗОНУ ХАОСА")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(calibrationPassed ? LabTheme.toxicGreen : Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!calibrationPassed)
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .onAppear {
            startCalibrationListener()
        }
    }

    private func startCalibrationListener() {
        sensor.startAudioMetering { peak in
            if peak > peakShout {
                peakShout = peak
            }
            if peak >= 75 && !calibrationPassed {
                DispatchQueue.main.async {
                    calibrationPassed = true
                    sensor.triggerClick()
                }
            }
        }
    }

    // MARK: - Системные проверки и запросы разрешений
    private func checkCurrentPermissions() {
        // Микрофон
        if #available(iOS 17.0, *) {
            micGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }

        // Камера
        cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

        // Пуши
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.pushGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestMicrophone() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.micGranted = granted
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.micGranted = granted
                }
            }
        }
    }

    private func requestCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraGranted = granted
                }
            }
        } else {
            DispatchQueue.main.async {
                self.cameraGranted = (status == .authorized)
            }
        }
    }

    private func requestPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.pushGranted = granted
            }
        }
    }
}
