import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var onTrailingTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DFColor.goldGradient)
                .frame(width: 3.5, height: 18)
                .shadow(color: DFColor.gold.opacity(0.6), radius: 6)

            Text(title)
                .font(DFFont.title2())
                .foregroundStyle(DFColor.text)

            Spacer()

            if let trailing, let onTrailingTap {
                Button(action: onTrailingTap) {
                    HStack(spacing: 3) {
                        Text(trailing)
                            .font(DFFont.caption())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(DFColor.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(DFColor.gold.opacity(0.12))
                            .overlay(Capsule().stroke(DFColor.gold.opacity(0.25), lineWidth: 0.6))
                    )
                }
            }
        }
        .padding(.horizontal, DFSpacing.xxl)
    }
}
