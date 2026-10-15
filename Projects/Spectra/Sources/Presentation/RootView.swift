import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 58, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                Text("Spectra")
                    .font(.largeTitle.bold())

                Text("Исследование локальной сети и устройств умного дома")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                ContentUnavailableView(
                    "Сканирование ещё не подключено",
                    systemImage: "network",
                    description: Text("Это стартовая версия интерфейса. Механизмы обнаружения устройств будут добавлены отдельными сервисами.")
                )
            }
            .padding(24)
            .navigationTitle("Spectra")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RootView()
}
