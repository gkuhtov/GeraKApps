import SwiftUI

// MARK: - Lab Colors & Gradients
public enum LabTheme {
    public static let backgroundDark = Color(red: 0.05, green: 0.06, blue: 0.08)
    public static let glassFill = Color.white.opacity(0.06)
    public static let glassBorder = Color.white.opacity(0.18)
    public static let toxicGreen = Color(red: 0.0, green: 1.0, blue: 0.53)
    public static let hazardOrange = Color(red: 1.0, green: 0.45, blue: 0.0)
    public static let alertRed = Color(red: 1.0, green: 0.15, blue: 0.25)
    public static let cyanBeam = Color(red: 0.0, green: 0.8, blue: 1.0)
}

// MARK: - Liquid Glass Card Modifier
public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var borderOpacity: Double

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LabTheme.glassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(borderOpacity), location: 0.0),
                                .init(color: Color.white.opacity(0.03), location: 0.4),
                                .init(color: LabTheme.cyanBeam.opacity(borderOpacity * 0.4), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, borderOpacity: Double = 0.25) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, borderOpacity: borderOpacity))
    }
}
