import SwiftUI

enum AppTheme {
    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.204, green: 0.827, blue: 0.600)
            : Color(red: 0.063, green: 0.725, blue: 0.506)
    }

    static func elapsedText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.910, green: 0.365, blue: 0.447)
            : Color(red: 0.788, green: 0.302, blue: 0.384)
    }

    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.122, green: 0.082, blue: 0.208),
                    Color(red: 0.071, green: 0.102, blue: 0.180),
                    Color(red: 0.059, green: 0.090, blue: 0.165),
                    Color(red: 0.086, green: 0.125, blue: 0.196),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.992, green: 0.957, blue: 1.0),
                Color(red: 0.941, green: 0.976, blue: 1.0),
                Color(red: 1.0, green: 0.969, blue: 0.929),
                Color(red: 0.973, green: 0.980, blue: 0.988),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.059, green: 0.090, blue: 0.165)
            : .white
    }

    static func surfaceElevated(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.118, green: 0.161, blue: 0.231)
            : Color(red: 0.945, green: 0.961, blue: 0.976)
    }

    static func textMuted(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.580, green: 0.639, blue: 0.722)
            : Color(red: 0.392, green: 0.455, blue: 0.545)
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.200, green: 0.255, blue: 0.333)
            : Color(red: 0.796, green: 0.835, blue: 0.882)
    }
}

enum GlassCapabilities {
    static var supportsLiquidGlass: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}

// MARK: - Modifiers

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.clear.tint(tint.opacity(0.55)), in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

struct GlassCircleModifier: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                content.glassEffect(.clear.tint(tint.opacity(0.55)), in: .circle)
            } else {
                content.glassEffect(.clear, in: .circle)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

struct GlassInputModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(AppTheme.surface(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(AppTheme.border(for: colorScheme))
                )
        }
    }
}

struct GlassSheetBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .presentationBackground {
                    Rectangle()
                        .fill(.clear)
                        .glassEffect(.clear, in: .rect(cornerRadius: 0))
                        .ignoresSafeArea()
                }
        } else {
            content
                .presentationBackground(AppTheme.surface(for: colorScheme))
        }
    }
}

struct GlassContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                content
            }
        } else {
            content
        }
    }
}

struct GlassNavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

// MARK: - Button Styles

struct GlassPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(colorScheme == .dark ? Color(red: 0.008, green: 0.027, blue: 0.090) : .white)
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.clear)
                        .glassEffect(
                            .clear.tint(AppTheme.accent(for: colorScheme).opacity(0.5)),
                            in: .rect(cornerRadius: 14)
                        )
                        .allowsHitTesting(false)
                }
                .opacity(isDisabled ? 0.6 : (configuration.isPressed ? 0.85 : 1))
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        } else {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent(for: colorScheme))
                .foregroundStyle(colorScheme == .dark ? Color(red: 0.008, green: 0.027, blue: 0.090) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .opacity(isDisabled ? 0.6 : (configuration.isPressed ? 0.85 : 1))
        }
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.clear)
                        .glassEffect(.clear, in: .rect(cornerRadius: 14))
                        .allowsHitTesting(false)
                }
                .opacity(configuration.isPressed ? 0.85 : 1)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        } else {
            configuration.label
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.border(for: colorScheme))
                )
                .opacity(configuration.isPressed ? 0.85 : 1)
        }
    }
}

struct GlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func glassPanel(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, tint: tint))
    }

    func glassCircle(tint: Color? = nil) -> some View {
        modifier(GlassCircleModifier(tint: tint))
    }

    func glassInput(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassInputModifier(cornerRadius: cornerRadius))
    }

    func glassSheetBackground() -> some View {
        modifier(GlassSheetBackgroundModifier())
    }

    func glassContainer() -> some View {
        modifier(GlassContainerModifier())
    }

    func glassNavigationBar() -> some View {
        modifier(GlassNavigationBarModifier())
    }
}

// MARK: - Container Views

struct AdaptiveGlassContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12, content: content)
        } else {
            content()
        }
    }
}

struct AppPageBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var imageOpacity: Double {
        colorScheme == .dark ? 0.14 : 0.12
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
            Image("Background")
                .resizable()
                .scaledToFill()
                .opacity(imageOpacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
