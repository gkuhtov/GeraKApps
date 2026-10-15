import SwiftUI

public struct MuseumView: View {
    @Environment(\.dismiss) private var dismiss
    private let museum = MuseumManager.shared
    private let personality = PersonalityEngine.shared

    @State private var selectedArtifact: MuseumArtifact?

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Шапка музея
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🏛️ ЗАЛ СЛАВЫ И ПОЗОРА")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.hazardOrange)
                                .tracking(2)
                            Text("Музей катастроф")
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

                    // Статусная плашка
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("СОБРАНО ЭКСПОНАТОВ УРОНА")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(museum.unlockedCount) из \(museum.totalCount) АРТЕФАКТОВ")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.toxicGreen)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .liquidGlass(cornerRadius: 18, borderOpacity: 0.3)

                    // Сетка 2 колонки
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(museum.artifacts) { item in
                            artifactCard(item)
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $selectedArtifact) { artifact in
            artifactDetailView(artifact)
        }
    }

    @ViewBuilder
    private func artifactCard(_ item: MuseumArtifact) -> some View {
        Button {
            if item.isUnlocked {
                personality.say("Смотришь на \(item.title)? Твоих рук дело, варвар.", emotion: .mocking)
                selectedArtifact = item
            } else {
                personality.say("Этот экспонат ещё цел. Иди ломай в Лаборатории!", emotion: .aggressive)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(item.isUnlocked ? item.emoji : "🔒")
                        .font(.system(size: 32))
                    Spacer()
                    Text(item.category.uppercased())
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(item.isUnlocked ? item.accentColor : .white.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.isUnlocked ? item.title : "Засекречено")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(item.isUnlocked ? .white : .white.opacity(0.4))
                        .lineLimit(1)

                    Text(item.isUnlocked ? (item.destructionDate ?? "Сломано") : "Ещё не уничтожено")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: 20, borderOpacity: item.isUnlocked ? 0.35 : 0.1)
        }
        .buttonStyle(.plain)
    }

    // Детальный просмотр экспоната
    @ViewBuilder
    private func artifactDetailView(_ item: MuseumArtifact) -> some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(item.emoji)
                    .font(.system(size: 72))
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(item.accentColor, lineWidth: 2))

                VStack(spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("Категория: \(item.category)")
                        .font(.system(size: 13))
                        .foregroundColor(item.accentColor)
                }

                Text(item.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(alignment: .top, spacing: 8) {
                    Text("🧑‍🔬")
                    Text(item.professorVerdict)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 40)
        }
    }
}
