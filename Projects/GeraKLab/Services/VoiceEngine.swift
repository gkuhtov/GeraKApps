import AVFoundation

public final class VoiceEngine: NSObject, @unchecked Sendable {
    public static let shared = VoiceEngine()

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
    }

    private func bestRussianVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "ru-RU" }
        
        if let premium = voices.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "ru-RU")
    }

    public func speak(_ text: String, emotion: VoiceEmotion = .neutral) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestRussianVoice()

        switch emotion {
        case .aggressive:
            utterance.rate = 0.54
            utterance.pitchMultiplier = 0.88
            utterance.volume = 1.0
            utterance.preUtteranceDelay = 0.05
        case .whisper:
            utterance.rate = 0.44
            utterance.pitchMultiplier = 1.15
            utterance.volume = 0.65
        case .mocking:
            utterance.rate = 0.50
            utterance.pitchMultiplier = 1.25
            utterance.volume = 0.95
        case .panic:
            utterance.rate = 0.62
            utterance.pitchMultiplier = 1.35
            utterance.volume = 1.0
        case .neutral:
            utterance.rate = 0.50
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.9
        }

        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
