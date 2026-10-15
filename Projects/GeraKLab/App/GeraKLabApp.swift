import SwiftUI

@main
struct GeraKLabApp: App {
    init() {
        // Прогрев менеджеров и конфигурации при холодном старте
        _ = LabConfigLoader.shared
        _ = AudioRouteManager.shared
        _ = PersonalityEngine.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
