import SwiftUI

struct ToastView: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = DFColor.gold

    var body: some View {
        HStack(spacing: DFSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(message)
                .font(DFFont.callout())
                .foregroundStyle(DFColor.text)
        }
        .padding(.horizontal, DFSpacing.xl)
        .padding(.vertical, DFSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DFRadius.xl))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var show: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if show {
                    VStack {
                        Spacer()
                        ToastView(message: message)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.bottom, 40)
                    .onTapGesture { withAnimation { show = false } }
                    .task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { show = false }
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: show)
    }
}

extension View {
    func toast(_ show: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(show: show, message: message))
    }
}
