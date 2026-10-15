import Foundation
import CoreMotion

@Observable
public final class MotionEngine {
    public static let shared = MotionEngine()

    public var currentGForce: Double = 1.0
    public var peakGForce: Double = 1.0
    public var pitch: Double = 0.0
    public var roll: Double = 0.0
    public var isTracking: Bool = false

    private let motionManager = CMMotionManager()
    private var timer: Timer?

    private init() {}

    public func startTracking(onPeak: ((Double) -> Void)? = nil) {
        guard motionManager.isDeviceMotionAvailable else {
            startSimulation(onPeak: onPeak)
            return
        }

        isTracking = true
        currentGForce = 1.0
        peakGForce = 1.0
        motionManager.deviceMotionUpdateInterval = 0.04
        motionManager.startDeviceMotionUpdates()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
            guard let self = self, let motion = self.motionManager.deviceMotion else { return }

            let x = motion.userAcceleration.x
            let y = motion.userAcceleration.y
            let z = motion.userAcceleration.z
            let totalG = sqrt(x * x + y * y + z * z) + 1.0

            DispatchQueue.main.async {
                self.currentGForce = totalG
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
                if totalG > self.peakGForce {
                    self.peakGForce = totalG
                    onPeak?(totalG)
                }
            }
        }
    }

    private func startSimulation(onPeak: ((Double) -> Void)?) {
        isTracking = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let simulatedG = Double.random(in: 1.0...4.0)
            DispatchQueue.main.async {
                self.currentGForce = simulatedG
                self.pitch = Double.random(in: -0.2...0.2)
                self.roll = Double.random(in: -0.2...0.2)
                if simulatedG > self.peakGForce {
                    self.peakGForce = simulatedG
                    onPeak?(simulatedG)
                }
            }
        }
    }

    public func stopTracking() {
        timer?.invalidate()
        timer = nil
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
        isTracking = false
        currentGForce = 1.0
        pitch = 0.0
        roll = 0.0
    }
}
