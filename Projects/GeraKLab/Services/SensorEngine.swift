import AVFoundation
import UIKit

@Observable
public final class SensorEngine: NSObject {
    public static let shared = SensorEngine()

    public var currentDecibels: Float = 0.0
    public var isListening: Bool = false

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private var tempFileURL: URL?

    private override init() {
        super.init()
        DispatchQueue.main.async {
            self.impactFeedback.prepare()
            self.notificationFeedback.prepare()
        }
    }

    /// Старт безопасного замера шума
    public func startAudioMetering(onPeakReached: ((Float) -> Void)? = nil) {
        guard !isListening else { return }

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if granted {
                    self.startHardwareRecorder(onPeakReached: onPeakReached)
                } else {
                    self.startSimulatedMetering(onPeakReached: onPeakReached)
                }
            }
        }
    }

    private func startHardwareRecorder(onPeakReached: ((Float) -> Void)?) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("meter_\(UUID().uuidString.prefix(6)).m4a")
            self.tempFileURL = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            guard let recorder = audioRecorder else {
                startSimulatedMetering(onPeakReached: onPeakReached)
                return
            }

            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                startSimulatedMetering(onPeakReached: onPeakReached)
                return
            }

            isListening = true

            levelTimer?.invalidate()
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let rec = self.audioRecorder, rec.isRecording else { return }
                rec.updateMeters()
                let power = rec.averagePower(forChannel: 0)
                let normalized = max(10, min(120, power + 105))

                DispatchQueue.main.async {
                    self.currentDecibels = normalized
                    if normalized > 75 {
                        onPeakReached?(normalized)
                    }
                }
            }
        } catch {
            print("[SensorEngine] Ошибка сессии: \(error)")
            startSimulatedMetering(onPeakReached: onPeakReached)
        }
    }

    private func startSimulatedMetering(onPeakReached: ((Float) -> Void)?) {
        isListening = true
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let noise = Float.random(in: 40.0...78.0)
            DispatchQueue.main.async {
                self.currentDecibels = noise
                if noise > 75 {
                    onPeakReached?(noise)
                }
            }
        }
    }

    public func stopAudioMetering() {
        levelTimer?.invalidate()
        levelTimer = nil

        if let rec = audioRecorder {
            if rec.isRecording {
                rec.stop()
            }
            audioRecorder = nil
        }

        isListening = false
        currentDecibels = 0.0

        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            tempFileURL = nil
        }
    }

    public func triggerExplosionHaptics() {
        DispatchQueue.main.async {
            self.notificationFeedback.notificationOccurred(.error)
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                    self.impactFeedback.impactOccurred(intensity: 1.0)
                }
            }
        }
    }

    public func triggerClick() {
        DispatchQueue.main.async {
            self.impactFeedback.impactOccurred(intensity: 0.8)
        }
    }
}
