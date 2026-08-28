import SwiftUI

struct Badge: View {
    let text: String
    var color: Color = DFColor.gold

    var body: some View {
        Text(text.uppercased())
            .font(DFFont.small())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DFRadius.sm))
    }
}
