import SwiftUI

public struct HomeView: View {
    private let personality = PersonalityEngine.shared
    @State private var activeExperiment: ExperimentItem?
    @State private var showSettings: Bool = false

    private let dailyExperiment = ExperimentItem(
        id: "exp_nitro",
        title: "Капля нитроглицерина",
        subtitle: "Замри и не дыши 5 секунд",
        emoji: "🧪",
        requiredHardware: "Акселерометр + Микрофон",
        accentColor: LabTheme.alertRed,
        dangerLevel: 5,
        mechanic: "nitro_freeze"
    )

    private let operationalExperiments: [ExperimentItem] = [
        ExperimentItem(id: "exp_core", title: "Удержи ядро реактора", subtitle: "Баланс гироскопа", emoji: "☢️", requiredHardware: "Гироскоп", accentColor: LabTheme.cyanBeam, dangerLevel: 5, mechanic: "core_balance"),
        ExperimentItem(id: "exp_traffic", title: "Красный / Зелёный свет", subtitle: "Тряска и мгновенный стоп", emoji: "🚦", requiredHardware: "Акселерометр", accentColor: LabTheme.toxicGreen, dangerLevel: 4, mechanic: "red_light_green_light"),
        ExperimentItem(id: "exp_strobe_tap", title: "Тап-пулемёт", subtitle: "Тапы под стробоскоп", emoji: "🔨", requiredHardware: "Вспышка + Дисплей", accentColor: LabTheme.alertRed, dangerLevel: 4, mechanic: "strobe_touch"),
        ExperimentItem(id: "exp_audio_target", title: "Голосовой тир", subtitle: "Коридор 60-80 дБ", emoji: "🎯", requiredHardware: "Микрофон", accentColor: LabTheme.hazardOrange, dangerLevel: 3, mechanic: "audio_scream"),
        ExperimentItem(id: "exp_facepalm", title: "Экстренный фэйспалм", subtitle: "Тест у лба", emoji: "🤦‍♂️", requiredHardware: "Датчик приближения", accentColor: LabTheme.cyanBeam, dangerLevel: 2, mechanic: "proximity_facepalm")
    ]

    public init() {}

    public var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    topBar
                        .padding(.top, 24)

                    speechBubbleSection

                    dailyExperimentSection

                    operationalSection

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $activeExperiment) { experiment in
            ExperimentExecutionView(experiment: experiment)
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ГЛАВНЫЙ ТЕРМИНАЛ")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.cyanBeam)
                    .tracking(2)
                Text("GeraKLab Core")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    private var speechBubbleSection: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("🧑‍🔬")
                .font(.system(size: 34))
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("ПРОФЕССОР")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(LabTheme.hazardOrange)
                    .tracking(1.5)

                Text(personality.currentSpeech)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
    }

    private var dailyExperimentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💥 ЭКСПЕРИМЕНТ ДНЯ")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(LabTheme.alertRed)
                .tracking(2)

            Button {
                activeExperiment = dailyExperiment
            } label: {
                HStack(spacing: 16) {
                    Text(dailyExperiment.emoji)
                        .font(.system(size: 40))
                        .frame(width: 64, height: 64)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(dailyExperiment.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)

                        Text(dailyExperiment.description)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))

                        Text(dailyExperiment.requiredHardware.uppercased())
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(dailyExperiment.accentColor)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16)
                .liquidGlass(cornerRadius: 24, borderOpacity: 0.35)
            }
            .buttonStyle(.plain)
        }
    }

    private var operationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡ ОПЕРАТИВНЫЕ ТЕСТЫ")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(LabTheme.toxicGreen)
                .tracking(2)

            VStack(spacing: 10) {
                ForEach(operationalExperiments, id: \.id) { item in
                    Button {
                        activeExperiment = item
                    } label: {
                        HStack(spacing: 14) {
                            Text(item.emoji)
                                .font(.system(size: 26))
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text(item.requiredHardware)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(item.accentColor)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(12)
                        .liquidGlass(cornerRadius: 18, borderOpacity: 0.2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
