import AVFoundation
import AudioToolbox

public enum LabSoundCue: String {
    // Реплики профессора
    case expStart = "voice_exp_start"
    case countdownPanic = "voice_countdown_panic"
    case screamSuccess = "voice_scream_success"
    case failShame = "voice_fail_shame"
    case momModeEngaged = "voice_mom_mode"
    
    // Эффекты железа (SFX)
    case explosion = "sfx_explosion"
    case sirenAlarm = "sfx_alarm"
    case clickTick = "sfx_tick"
    case heartBeat = "sfx_heartbeat"
}

public final class SoundManager: NSObject, Sendable {
    public static let shared = SoundManager()

    private override init() {
        super.init()
    }

    /// Воспроизведение звукового эффекта или нейро-реплики с фолбэком
    public func playCue(_ cue: LabSoundCue, fallbackText: String? = nil, emotion: VoiceEmotion = .aggressive) {
        // Проверяем, зашит ли в проект аудиофайл (.m4a / .wav / .mp3)
        if let soundURL = Bundle.main.url(forResource: cue.rawValue, withExtension: "m4a") ??
                          Bundle.main.url(forResource: cue.rawValue, withExtension: "wav") ??
                          Bundle.main.url(forResource: cue.rawValue, withExtension: "mp3") {
            playAudioFile(url: soundURL)
        } else {
            // Если файла нет, используем системные звуковые генераторы + настроенный VoiceEngine
            triggerSystemHardwareSound(for: cue)
            if let text = fallbackText {
                VoiceEngine.shared.speak(text, emotion: emotion)
            }
        }
    }

    /// Проигрывание аудиофайла через системную аудио-сессию
    private func playAudioFile(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true)

                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
            } catch {
                print("[SoundManager] Ошибка воспроизведения аудио: \(error)")
            }
        }
    }

    /// Встроенные системные сигналы iOS для эффектов, если файлов нет в бандле
    private func triggerSystemHardwareSound(for cue: LabSoundCue) {
        switch cue {
        case .explosion:
            // Системный сигнал критического сбоя
            AudioServicesPlaySystemSound(1073)
        case .sirenAlarm:
            AudioServicesPlaySystemSound(1005)
        case .clickTick:
            AudioServicesPlaySystemSound(1104)
        case .heartBeat:
            AudioServicesPlaySystemSound(1057)
        default:
            break
        }
    }
}
