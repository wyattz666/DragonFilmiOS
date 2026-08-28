import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: DFSpacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(DFColor.textMuted)

            VStack(spacing: DFSpacing.sm) {
                Text(title)
                    .font(DFFont.headline())
                    .foregroundStyle(DFColor.text)
                Text(message)
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.textDim)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}
