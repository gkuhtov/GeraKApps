import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private let personality = PersonalityEngine.shared
    private let museum = MuseumManager.shared
    private let stressRunner = StressTestRunner.shared

    // Тумблеры поведения
    @State private var safeForMomMode: Bool = false
    @State private var toxicityLevel: Double = 85.0
    @State private var autonomyMode: String = "Безумный"

    // Оформление
    @State private var glassIntensity: Double = 0.85

    // Модальные экраны
    @State private var showMuseum: Bool = false
    @State private var showPrivateLab: Bool = false

    private let autonomyLevels = ["Осторожный", "Обычный", "Безумный"]

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Шапка
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("⚙️ СИСТЕМНЫЙ УЗЕЛ")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.cyanBeam)
                                .tracking(2)
                            Text("Настройки лаборатории")
                                .font(.system(size: 24, weight: .bold))
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

                    // 🧑‍🔬 Профиль
                    profileSection

                    // 🎭 Поведение
                    behaviorSection

                    // 🎨 Оформление
                    appearanceSection

                    // 🏛️ Музей катастроф
                    museumSection

                    // 🔐 Датчики
                    sensorsSection

                    // 🩺 Интерактивная диагностика
                    diagnosticsSection

                    // 📦 Конфигурация и сброс
                    configAndResetSection

                    // 🔒 Скрытый протокол
                    secretProtocolTrigger

                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            // Оверлей активной прожарки
            if stressRunner.isRunning {
                stressOverlay
            }
        }
        .sheet(isPresented: $showMuseum) {
            MuseumView()
        }
        .fullScreenCover(isPresented: $showPrivateLab) {
            PrivateLabView()
        }
    }

    // MARK: - 🧑‍🔬 Профиль
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Text("🧑‍🔬")
                    .font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Лаборант #4092")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Титул: Главный разрушитель динамиков")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(LabTheme.toxicGreen)
                }
                Spacer()
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
    }

    // MARK: - 🎭 Поведение и мат
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("🎭 ПОВЕДЕНИЕ И ТОКСИЧНОСТЬ")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(LabTheme.hazardOrange)
                .tracking(1.5)

            Toggle(isOn: $safeForMomMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Режим «При маме»")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Заменяет трёхэтажный мат на сарказм и «пииип»")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .tint(LabTheme.toxicGreen)
            .onChange(of: safeForMomMode) { _, enabled in
                if enabled {
                    personality.say("Цензуру включил? Ну ладно, буду вежливым ублюдком.", emotion: .whisper)
                } else {
                    personality.say("О, тормоза сняты! Понеслась моча по трубам!", emotion: .aggressive)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 6) {
                Text("Уровень автономности: \(autonomyMode)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Picker("Автономность", selection: $autonomyMode) {
                    ForEach(autonomyLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Градус токсичности")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(toxicityLevel))%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(LabTheme.alertRed)
                }
                Slider(value: $toxicityLevel, in: 0...100, step: 5)
                    .tint(LabTheme.alertRed)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.25)
    }

    // MARK: - 🎨 Оформление Liquid Glass
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎨 ЖИДКОЕ СТЕКЛО (LIQUID GLASS)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(LabTheme.cyanBeam)
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Плотность размытия")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(glassIntensity * 100))%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(LabTheme.cyanBeam)
                }
                Slider(value: $glassIntensity, in: 0.2...1.0)
                    .tint(LabTheme.cyanBeam)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.25)
    }

    // MARK: - 🏛️ Музей катастроф
    private var museumSection: some View {
        Button {
            personality.say("Пойдём поглядим на твои подвиги вандализма.", emotion: .mocking)
            showMuseum = true
        } label: {
            HStack(spacing: 14) {
                Text("🏛️")
                    .font(.system(size: 30))
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Музей разбитых надежд")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Открыто: \(museum.unlockedCount) из \(museum.totalCount) артефактов урона")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .liquidGlass(cornerRadius: 22, borderOpacity: 0.25)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 🔐 Датчики
    private var sensorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🔐 РЕАЛЬНЫЕ ДАТЧИКИ IOS")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .tracking(1.5)

            sensorBadge(title: "Микрофон", status: "Разрешено", active: true)
            sensorBadge(title: "Камера и FaceID", status: "Разрешено", active: true)
            sensorBadge(title: "Taptic Engine (Вибро)", status: "Доступен", active: true)
            sensorBadge(title: "LiDAR-сканер", status: "В ожидании", active: false)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.25)
    }

    private func sensorBadge(title: String, status: String, active: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text(status)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(active ? LabTheme.toxicGreen : Color.white.opacity(0.3))
        }
    }

    // MARK: - 🩺 Прожарка железа
    private var diagnosticsSection: some View {
        Button {
            stressRunner.startStressTest {}
        } label: {
            HStack {
                Spacer()
                Image(systemName: "flame.fill")
                Text("ПРОЖАРКА ВСЕХ СИСТЕМ (ТЕСТ)")
                    .font(.system(size: 13, weight: .black))
                Spacer()
            }
            .foregroundColor(.black)
            .padding(.vertical, 14)
            .background(LabTheme.hazardOrange)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Оверлей стресс-теста
    private var stressOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🔥")
                    .font(.system(size: 64))

                Text("ПРОЖАРКА СИСТЕМ")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.hazardOrange)

                Text(stressRunner.currentStage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [LabTheme.hazardOrange, LabTheme.alertRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(stressRunner.progress))
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, 40)
            }
            .padding(24)
            .liquidGlass(cornerRadius: 24, borderOpacity: 0.4)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - 📦 Конфигурация и сброс
    private var configAndResetSection: some View {
        HStack(spacing: 12) {
            Button {
                personality.say("Конфиг скопирован в буфер. Не потеряй, умник.", emotion: .neutral)
            } label: {
                Text("Экспорт JSON")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                personality.say("Сбросить всё к хуям? Ну давай, начинай сначала.", emotion: .aggressive)
            } label: {
                Text("Сброс памяти")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(LabTheme.alertRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LabTheme.alertRed.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - 🔒 Скрытый протокол (Private Lab)
    private var secretProtocolTrigger: some View {
        VStack(spacing: 6) {
            Text("GeraKLab Engine Core v2.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))

            Text("🔒 Удерживай 3 сек для Private Lab")
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(LabTheme.alertRed.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 2.5) {
            personality.say("Доступ в Private Lab разрешён. Добро пожаловать во тьму.", emotion: .whisper)
            showPrivateLab = true
        }
    }
}
