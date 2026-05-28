import SwiftUI

struct MealButtonView: View {
    let backgroundColor: Color
    let progress: Double
    let isLoading: Bool
    let action: () -> Void

    // Web MealButton.vue: container 16rem (256pt), button w-56 (224pt),
    // SVG viewBox 100, ring r=47, stroke-width=5 → stroke = 5% container, diameter = 94% container
    private let containerSize: CGFloat = 256
    private let buttonSize: CGFloat = 224
    private var ringDiameter: CGFloat { containerSize * 94 / 100 }
    private var ringLineWidth: CGFloat { containerSize * 5 / 100 }
    private var pacManSize: CGFloat { buttonSize * 0.54 }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var ringOpacity: Double {
        clampedProgress <= 0 ? 0 : 0.25 + clampedProgress * 0.75
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                PacManIcon(showPellets: false, squareFrame: true)
                    .frame(width: pacManSize, height: pacManSize)
                    .allowsHitTesting(false)
            }
            .frame(width: buttonSize, height: buttonSize)
            .contentShape(Circle())
        }
        .buttonStyle(MealButtonStyle(isLoading: isLoading))
        .background {
            ZStack {
                progressRing
                Circle()
                    .fill(backgroundColor)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .frame(width: containerSize, height: containerSize)
            .allowsHitTesting(false)
        }
        .frame(width: containerSize, height: containerSize)
        .disabled(isLoading)
        .accessibilityLabel("Yedim")
    }

    private var progressRing: some View {
        Circle()
            .trim(from: 0, to: clampedProgress)
            .stroke(backgroundColor, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .opacity(ringOpacity)
            .animation(.easeInOut(duration: 0.7), value: clampedProgress)
            .frame(width: ringDiameter, height: ringDiameter)
    }
}

private struct MealButtonStyle: ButtonStyle {
    let isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isLoading ? 0.7 : 1)
            .scaleEffect(isLoading ? 0.98 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.7), value: isLoading)
    }
}

#Preview {
    MealButtonView(backgroundColor: .green, progress: 0.6, isLoading: false) {}
}
