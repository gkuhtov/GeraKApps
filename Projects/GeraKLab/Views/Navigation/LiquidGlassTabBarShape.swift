import SwiftUI

/// Монолитная форма панели с органическим выступом под центральную кнопку 🎲
public struct LiquidGlassTabBarShape: Shape {
    public var curveOffset: CGFloat = 36
    public var curveWidth: CGFloat = 90

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = rect.width / 2
        let startX = center - curveWidth / 2
        let endX = center + curveWidth / 2

        // Левый верхний угол
        path.move(to: CGPoint(x: 24, y: 0))
        path.addLine(to: CGPoint(x: startX, y: 0))

        // Плавная органическая кривая выгиба вверх под кость 🎲
        path.addCurve(
            to: CGPoint(x: center, y: -curveOffset),
            control1: CGPoint(x: startX + 22, y: 0),
            control2: CGPoint(x: center - 24, y: -curveOffset)
        )
        path.addCurve(
            to: CGPoint(x: endX, y: 0),
            control1: CGPoint(x: center + 24, y: -curveOffset),
            control2: CGPoint(x: endX - 22, y: 0)
        )

        // Правый верхний угол
        path.addLine(to: CGPoint(x: rect.width - 24, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - 24, y: 24),
            radius: 24,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Правый нижний угол
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 24))
        path.addArc(
            center: CGPoint(x: rect.width - 24, y: rect.height - 24),
            radius: 24,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Левый нижний угол
        path.addLine(to: CGPoint(x: 24, y: rect.height))
        path.addArc(
            center: CGPoint(x: 24, y: rect.height - 24),
            radius: 24,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Замыкание в левый верхний
        path.addLine(to: CGPoint(x: 0, y: 24))
        path.addArc(
            center: CGPoint(x: 24, y: 24),
            radius: 24,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
