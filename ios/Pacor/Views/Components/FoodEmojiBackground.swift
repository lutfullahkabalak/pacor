import SwiftUI

struct FoodEmojiBackground: View {
    private let emojis = ["🍎", "🥑", "🍕", "🍔", "🥗", "🍳", "🍌", "🥕", "🍇", "🧀", "🍞", "🥦"]

    var body: some View {
        GeometryReader { geometry in
            let columns = 4
            let rows = 6
            let cellWidth = geometry.size.width / CGFloat(columns)
            let cellHeight = geometry.size.height / CGFloat(rows)

            ZStack {
                ForEach(0..<(columns * rows), id: \.self) { index in
                    let column = index % columns
                    let row = index / columns
                    Text(emojis[index % emojis.count])
                        .font(.system(size: 28))
                        .opacity(0.12)
                        .position(
                            x: cellWidth * (CGFloat(column) + 0.5),
                            y: cellHeight * (CGFloat(row) + 0.5)
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    FoodEmojiBackground()
}
