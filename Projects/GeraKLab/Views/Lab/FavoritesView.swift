import SwiftUI

public struct FavoriteExperimentItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let emoji: String
    public var runCount: Int
    public let requiredHardware: String
    public let accentColor: Color

    public var verdict: String {
        switch runCount {
        case 0...2:
            return "Попробовал, обосрался, но зачем-то сохранил в закладки."
        case 3...6:
            return "Друзьям уже раз десять показал, у них уши вянут от визгов. Тормози!"
        default:
            return "Клинический мазохизм. Тебе реально по кайфу, когда на тебя орут трёхэтажным."
        }
    }

    public var statusBadge: String {
        switch runCount {
        case 0...2:
            return "СВЕЖИЙ ГРЕХ"
        case 3...6:
            return "НА ПОВТОРЕ"
        default:
            return "ЛЮБИМАЯ ПЫТКА"
        }
    }

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

public struct FavoritesView: View {
    private let personality = PersonalityEngine.shared
    @State private var activeExperiment: ExperimentItem?

    @State private var favorites: [FavoriteExperimentItem] = [
        FavoriteExperimentItem(
            id: "polygraph_extreme",
            title: "Детектор пиздежа 18+",
            subtitle: "Сканирует палец и жестко глумится над ответом",
            emoji: "🫀",
            runCount: 11,
            requiredHardware: "Камера + Пульс",
            accentColor: LabTheme.toxicGreen
        ),
        FavoriteExperimentItem(
            id: "shake_bomb",
            title: "Тряси или пизданёт",
            subtitle: "Таймер тикает, пока телефон в движении",
            emoji: "💣",
            runCount: 4,
            requiredHardware: "Акселерометр",
            accentColor: LabTheme.hazardOrange
        ),
        FavoriteExperimentItem(
            id: "ultrasound_purge",
            title: "Ультразвуковой визг",
            subtitle: "Частоты от 15 кГц до паники кота",
            emoji: "🔊",
            runCount: 1,
            requiredHardware: "Динамики",
            accentColor: LabTheme.alertRed
        )
    ]

    private var totalRuns: Int {
        favorites.reduce(0) { $0 + $1.runCount }
    }

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Шапка со счетчиком
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("⭐ ЗОЛОТОЙ ФОНД РАЗЪЁБА")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(LabTheme.hazardOrange)
                            .tracking(2)
                        Text("Коллекция грехов")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Общий счетчик запусков избранного
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(totalRuns)")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(LabTheme.toxicGreen)
                        Text("ПРОГОНОВ ВСЕГО")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 54)

                // Карточки избранного
                VStack(spacing: 16) {
                    ForEach($favorites) { $item in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .center, spacing: 14) {
                                Text(item.emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 54, height: 54)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)

                                    // Крупный акцентный блок количества запусков
                                    HStack(spacing: 6) {
                                        Text("ЗАПУЩЕНО:")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white.opacity(0.5))

                                        Text("\(item.runCount)")
                                            .font(.system(size: 15, weight: .black, design: .monospaced))
                                            .foregroundColor(item.accentColor)

                                        Text(item.runCount == 1 ? "РАЗ" : (item.runCount < 5 ? "РАЗА" : "РАЗ"))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(item.accentColor)

                                        Text("• \(item.statusBadge)")
                                            .font(.system(size: 9, weight: .heavy))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                }

                                Spacer()

                                Button {
                                    item.runCount += 1
                                    triggerRerun(for: item)
                                } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 13, weight: .black))
                                        Text("ЕЩЁ")
                                            .font(.system(size: 10, weight: .black))
                                    }
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                                    .background(item.accentColor)
                                    .clipShape(Circle())
                                }
                            }

                            // Циничный вердикт персонажа
                            HStack(alignment: .top, spacing: 8) {
                                Text("💬")
                                    .font(.system(size: 12))
                                Text(item.verdict)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 22, borderOpacity: 0.3)
                        .onTapGesture {
                            item.runCount += 1
                            triggerRerun(for: item)
                        }
                    }
                }

                Spacer().frame(height: 110)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(item: $activeExperiment) { item in
            ExperimentExecutionView(experiment: item)
        }
    }

    private func triggerRerun(for item: FavoriteExperimentItem) {
        if item.runCount > 8 {
            personality.say("Уже \(item.runCount)-й раз?! Да ты реально конченый, у меня динамик щас отвалится!", emotion: .panic)
        } else if item.runCount > 3 {
            personality.say("Пошёл \(item.runCount)-й круг ада! Запускай это дерьмо!", emotion: .aggressive)
        } else {
            personality.say("Второй раз запустил, смелый какой. Пальцы береги!", emotion: .neutral)
        }
        activeExperiment = item.toExperimentItem()
    }
}
