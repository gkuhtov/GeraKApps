import AVFoundation

@Observable
public final class FlashlightEngine {
    public static let shared = FlashlightEngine()

    public var isStrobeActive: Bool = false
    private var strobeTimer: Timer?
    private var flashState: Bool = false

    private init() {}

    public func startStrobe(interval: Double = 0.08) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            isStrobeActive = true
            return
        }

        isStrobeActive = true
        strobeTimer?.invalidate()
        strobeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.flashState.toggle()
            do {
                try device.lockForConfiguration()
                if self.flashState {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }

    public func stopStrobe() {
        strobeTimer?.invalidate()
        strobeTimer = nil
        isStrobeActive = false

        if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
            try? device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        }
    }
}
