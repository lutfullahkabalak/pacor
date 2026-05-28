import SwiftUI

struct StatsFab: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(GlassIconButtonStyle())
        .glassCircle()
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .accessibilityLabel("İstatistikler")
    }
}

#Preview {
    StatsFab {}
        .padding()
}
