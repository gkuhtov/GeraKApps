import Foundation

@Observable
public final class LabConfigLoader {
    public static let shared = LabConfigLoader()

    public var experiments: [ExperimentItem] = []

    private init() {
        loadExperiments()
    }

    public func loadExperiments() {
        guard let url = Bundle.main.url(forResource: "experiments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([ExperimentItem].self, from: data) else {
            // Фолбэк дефолтных
            self.experiments = [
                ExperimentItem(id: "exp_01", title: "Капля нитроглицерина", description: "Замри и не дыши", emoji: "🧪", dangerLevel: 4, requiredHardware: "Акселерометр", hexColor: "#FF3B30", mechanic: "nitro_freeze"),
                ExperimentItem(id: "exp_06", title: "Акустический перегруз", description: "Крикни в микрофон", emoji: "💥", dangerLevel: 3, requiredHardware: "Микрофон", hexColor: "#FF2D55", mechanic: "audio_scream")
            ]
            return
        }
        self.experiments = list
    }
}
