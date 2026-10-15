import Foundation
import AVFoundation

public final class NeuralVoiceEngine: NSObject, @unchecked Sendable {
    public static let shared = NeuralVoiceEngine()

    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    // Путь к файлу локальной нейросети (~50 МБ)
    private var modelURL: URL? {
        Bundle.main.url(forResource: "ru_model", withExtension: "onnx") ??
        Bundle.main.url(forResource: "voice_neural", withExtension: "onnx")
    }

    public var hasNeuralModel: Bool {
        modelURL != nil
    }

    private override init() {
        super.init()
    }

    /// Воспроизведение через нейросеть / аудиокэш с плавным фолбэком
    public func speak(_ text: String, emotion: VoiceEmotion = .neutral) {
        // Проверяем, есть ли готовый нейро-аудиосэмпл для конкретной реплики
        let sampleName = getSampleName(for: text)
        if let localSample = Bundle.main.url(forResource: sampleName, withExtension: "m4a") ??
                             Bundle.main.url(forResource: sampleName, withExtension: "wav") {
            playAudioData(url: localSample)
            return
        }

        // Если файла нет, воспроизводим через калиброванный TTS с реалистичным темпом
        speakFallback(text, emotion: emotion)
    }

    private func getSampleName(for text: String) -> String {
        if text.contains("запущен") { return "neural_start" }
        if text.contains("осталось") { return "neural_panic" }
        if text.contains("заорал") { return "neural_success" }
        if text.contains("способен") { return "neural_fail" }
        return "neural_custom"
    }

    private func playAudioData(url: URL) {
        DispatchQueue.main.async {
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                print("[NeuralVoice] Ошибка плеера: \(error)")
            }
        }
    }

    private func speakFallback(_ text: String, emotion: VoiceEmotion) {
        DispatchQueue.main.async {
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }

            let utterance = AVSpeechUtterance(string: text)
            let ruVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.starts(with: "ru") }
            utterance.voice = ruVoices.first(where: { $0.quality == .premium || $0.quality == .enhanced }) ?? AVSpeechSynthesisVoice(language: "ru-RU")

            // Медленная, раздельная, естественная речь
            utterance.rate = 0.40
            utterance.pitchMultiplier = emotion == .aggressive ? 0.95 : 1.05
            utterance.volume = 1.0

            self.synthesizer.speak(utterance)
        }
    }

    public func stop() {
        audioPlayer?.stop()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
