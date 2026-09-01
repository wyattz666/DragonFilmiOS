import SwiftUI

/// Universal avatar image loader that supports both Base64 Data URLs and remote HTTP/HTTPS URLs (from Web/OAuth).
struct AvatarImage: View {
    let dataURL: String
    var placeholderText: String = "?"

    var body: some View {
        let clean = dataURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            placeholder
        } else if clean.hasPrefix("data:") {
            if let image = decodeBase64(clean) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        } else if clean.hasPrefix("http://") || clean.hasPrefix("https://") {
            if let url = URL(string: clean) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .tint(DFColor.gold)
                            .scaleEffect(0.6)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        } else if let image = decodeBase64("data:image/jpeg;base64," + clean) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(DFColor.bg3)
            .overlay(
                Text(placeholderText)
                    .font(DFFont.largeTitle())
                    .foregroundStyle(DFColor.gold)
            )
    }

    private func decodeBase64(_ str: String) -> UIImage? {
        guard let comma = str.firstIndex(of: ",") else {
            if let data = Data(base64Encoded: str) {
                return UIImage(data: data)
            }
            return nil
        }
        let b64Part = String(str[str.index(after: comma)...])
        guard let data = Data(base64Encoded: b64Part) else { return nil }
        return UIImage(data: data)
    }
}
