import AVFoundation
import SwiftUI

public enum AudioOutputDestination {
    case builtInSpeaker   // Встроенный динамик iPhone (кричим громко и четко)
    case headphones       // AirPods или проводные наушники (интимный едкий шепот)
    case bluetoothSpeaker // Внешняя колонка (подача на толпу)
}

@Observable
public final class AudioRouteManager {
    public static let shared = AudioRouteManager()

    public var currentDestination: AudioOutputDestination = .builtInSpeaker

    private init() {
        setupAudioSession()
        updateCurrentRoute()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[AudioRouteManager] Ошибка настройки сессии: \(error)")
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        updateCurrentRoute()
    }

    private func updateCurrentRoute() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        var destination: AudioOutputDestination = .builtInSpeaker

        for output in currentRoute.outputs {
            switch output.portType {
            case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                destination = .headphones
            case .airPlay:
                destination = .bluetoothSpeaker
            default:
                destination = .builtInSpeaker
            }
        }

        DispatchQueue.main.async {
            self.currentDestination = destination
        }
    }
}
