import SwiftUI

struct PinCodeField: View {
    @Binding var pin: String
    var length: Int = 4
    var onComplete: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.02)
                .frame(width: 1, height: 1)
                .onChange(of: pin) { oldValue, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(length))
                    if filtered != newValue {
                        pin = filtered
                        return
                    }

                    if filtered.count == length, oldValue.count < length {
                        isFocused = false
                        onComplete?()
                    }
                }

            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { index in
                    pinBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func pinBox(at index: Int) -> some View {
        let isFilled = index < pin.count
        let isActive = isFocused && pin.count == index

        return Text(isFilled ? "•" : "")
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .frame(width: 56, height: 64)
            .glassInput(cornerRadius: 14)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive ? AppTheme.accent(for: colorScheme) : AppTheme.border(for: colorScheme),
                        lineWidth: isActive ? 2 : 1
                    )
            }
            .animation(.easeOut(duration: 0.15), value: isActive)
            .animation(.easeOut(duration: 0.15), value: isFilled)
    }
}

#Preview {
    @Previewable @State var pin = "12"
    PinCodeField(pin: $pin)
        .padding()
}
