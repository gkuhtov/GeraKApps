import SwiftUI

public struct LabView: View {
    @State private var configLoader = LabConfigLoader.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Все"
    @State private var activeExperiment: ExperimentItem?

    private let filters = ["Все", "Микрофон", "Акселерометр", "Гироскоп", "Вспышка", "Приближение"]

    public init() {}

    private var filteredExperiments: [ExperimentItem] {
        configLoader.experiments.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)

            let matchesFilter = selectedFilter == "Все" ||
                item.requiredHardware.localizedCaseInsensitiveContains(selectedFilter)

            return matchesSearch && matchesFilter
        }
    }

    public var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🔬 ЗОНА ИСПЫТАНИЙ")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(LabTheme.cyanBeam)
                                .tracking(2)
                            Text("Каталог экспериментов")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 24)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Поиск пытки для железа...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .liquidGlass(cornerRadius: 16, borderOpacity: 0.2)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    selectedFilter = filter
                                } label: {
                                    Text(filter)
                                        .font(.system(size: 12, weight: selectedFilter == filter ? .bold : .medium))
                                        .foregroundColor(selectedFilter == filter ? .black : .white.opacity(0.7))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? LabTheme.toxicGreen : Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    LazyVStack(spacing: 14) {
                        ForEach(filteredExperiments) { experiment in
                            experimentCard(experiment)
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(item: $activeExperiment) { experiment in
            ExperimentExecutionView(experiment: experiment)
        }
    }

    private func experimentCard(_ item: ExperimentItem) -> some View {
        Button {
            activeExperiment = item
        } label: {
            HStack(spacing: 16) {
                Text(item.emoji)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        dangerStars(level: item.dangerLevel)
                    }

                    Text(item.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(item.requiredHardware)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(item.accentColor)
                }
                Spacer()
            }
            .padding(14)
            .liquidGlass(cornerRadius: 20, borderOpacity: 0.25)
        }
        .buttonStyle(.plain)
    }

    private func dangerStars(level: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? LabTheme.alertRed : Color.white.opacity(0.15))
                    .frame(width: 5, height: 5)
            }
        }
    }
}
