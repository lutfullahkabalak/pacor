import SwiftUI

struct PacManIcon: View {
    var headOnly = false
    var showPellets = true
    var squareFrame = false

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                PacManShape()
                    .fill(
                        Color(red: 0.961, green: 0.784, blue: 0.259),
                        style: FillStyle(eoFill: false, antialiased: true)
                    )

                Circle()
                    .fill(Color(red: 0.267, green: 0.267, blue: 0.267))
                    .frame(width: size * 0.09, height: size * 0.09)
                    .offset(x: -size * 0.11, y: -size * 0.17)

                if showPellets && !headOnly {
                    Circle()
                        .fill(Color(red: 0.961, green: 0.784, blue: 0.259))
                        .frame(width: size * 0.11, height: size * 0.11)
                        .offset(x: size * 0.22)

                    Circle()
                        .fill(Color(red: 0.961, green: 0.784, blue: 0.259))
                        .frame(width: size * 0.11, height: size * 0.11)
                        .offset(x: size * 0.38)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var aspectRatio: CGFloat {
        if squareFrame { return 1.0 }
        return headOnly ? 1.6 : 1.7
    }
}

struct PacManShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.46
        let mouthAngle = 35.0

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-mouthAngle),
            endAngle: .degrees(mouthAngle),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    PacManIcon(showPellets: false, squareFrame: true)
        .frame(width: 120, height: 120)
        .padding()
        .background(Color.gray.opacity(0.2))
}
