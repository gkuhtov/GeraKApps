import AVFoundation
import UIKit

@Observable
public final class StressTestRunner {
    public static let shared = StressTestRunner()

    public var isRunning: Bool = false
    public var currentStage: String = "Готовность"
    public var progress: Double = 0.0

    private let personality = PersonalityEngine.shared
    private let sensor = SensorEngine.shared

    private init() {}

    /// Запуск комплексного стресс-теста
    public func startStressTest(completion: @escaping () -> Void) {
        guard !isRunning else { return }
        isRunning = true
        progress = 0.0

        // Этап 1: Разогрев Taptic Engine
        currentStage = "Этап 1: Раскачка Taptic Engine"
        personality.say("Начинаем прогрев вибромотора. Держи крепче, щас вырвет из рук!", emotion: .aggressive)
        
        var step = 0
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.sensor.triggerClick()
            step += 1
            self.progress = Double(step) / 40.0

            if step >= 15 {
                timer.invalidate()
                self.runFlashStage(completion: completion)
            }
        }
    }

    /// Этап 2: Стробоскоп вспышки
    private func runFlashStage(completion: @escaping () -> Void) {
        currentStage = "Этап 2: Слеповой стробоскоп вспышки"
        personality.say("Береги глаза, лаборант! Врубаем стробоскоп на полную!", emotion: .panic)

        var flashes = 0
        Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.toggleTorch(on: flashes % 2 == 0)
            self.sensor.triggerClick()
            flashes += 1
            self.progress = 0.38 + Double(flashes) / 35.0

            if flashes >= 16 {
                timer.invalidate()
                self.toggleTorch(on: false)
                self.runFinalOverload(completion: completion)
            }
        }
    }

    /// Этап 3: Финальный пиковый разгон и взрыв
    private func runFinalOverload(completion: @escaping () -> Void) {
        currentStage = "Этап 3: Критическая перегрузка всех систем"
        personality.say("Внимание! Системы на пределе! Три, два, один... БАБАХ!", emotion: .panic)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            self.sensor.triggerExplosionHaptics()
            self.progress = 1.0
            self.currentStage = "Прожарка завершена! Железо выжило."
            self.personality.say("Экзекуция окончена. Твой телефон выдержал, а вот твоя нервная система — вряд ли.", emotion: .mocking)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isRunning = false
                completion()
            }
        }
    }

    /// Управление фонариком
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("[StressTestRunner] Ошибка фонарика: \(error)")
        }
    }
}
