import SwiftUI

@Observable
public final class PersonalityEngine {
    public static let shared = PersonalityEngine()

    public var currentSpeech: String = "Че встал? Выбирай эксперимент или телефон мне отдай."
    public var currentEmotion: VoiceEmotion = .mocking

    private let neuralVoice = NeuralVoiceEngine.shared
    private var idleTimer: Timer?

    private init() {
        resetIdleTimer()
    }

    public func say(_ text: String, emotion: VoiceEmotion = .neutral) {
        currentSpeech = text
        currentEmotion = emotion
        neuralVoice.speak(text, emotion: emotion)
        resetIdleTimer()
    }

    public func triggerDicePanic() {
        say("Кость брошена! Назад дороги нет, щас что-то ёбнет!", emotion: .panic)
    }

    public func userDidInteract() {
        resetIdleTimer()
    }

    public func resetIdleTimer() {
        idleTimer?.invalidate()
        
        // Если онбординг ещё не пройден — профессор молчит и не донимает
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        guard hasCompletedOnboarding else { return }

        idleTimer = Timer.scheduledTimer(withTimeInterval: 14.0, repeats: false) { [weak self] _ in
            self?.triggerIdleBanter()
        }
    }

    private func triggerIdleBanter() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        guard hasCompletedOnboarding else { return }

        let banters = [
            "Ты уснул там? Жми на кнопку, пока батарея не сдохла!",
            "Экран щас протрешь пальцем. Запускай разъёб!",
            "Я тут стою, процессор грею вхолостую. Ну-ка шевелись!"
        ]
        if let randomText = banters.randomElement() {
            say(randomText, emotion: .aggressive)
        }
    }
}
