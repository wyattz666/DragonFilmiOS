import SwiftUI

struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .clipped()
            } else {
                ZStack {
                    DFColor.bg3
                    if isLoading {
                        ProgressView()
                            .tint(DFColor.goldDim)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "film")
                            .font(.subheadline)
                            .foregroundStyle(DFColor.textMuted.opacity(0.5))
                    }
                }
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let rawURL = url?.trimmingCharacters(in: .whitespacesAndNewlines), !rawURL.isEmpty else {
            loadedImage = nil
            return
        }

        let normalizedURLString: String
        if rawURL.hasPrefix("//") {
            normalizedURLString = "https:" + rawURL
        } else if !rawURL.hasPrefix("http://") && !rawURL.hasPrefix("https://") {
            normalizedURLString = "https://" + rawURL
        } else {
            normalizedURLString = rawURL
        }

        let cacheKey = NSString(string: normalizedURLString)
        if let cached = ImageCache.shared.object(forKey: cacheKey) {
            loadedImage = cached
            return
        }

        guard let imageURL = URL(string: normalizedURLString)
                ?? URL(string: normalizedURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            return
        }

        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        do {
            var request = URLRequest(url: imageURL)
            request.timeoutInterval = 15
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, response) = try await imageSession.data(for: request)

            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
               let uiImage = UIImage(data: data) {
                ImageCache.shared.setObject(uiImage, forKey: cacheKey)
                withAnimation(.easeInOut(duration: 0.2)) {
                    loadedImage = uiImage
                }
            }
        } catch {}
    }
}

private final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {
        cache.countLimit = 500
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    func object(forKey key: NSString) -> UIImage? { cache.object(forKey: key) }
    func setObject(_ obj: UIImage, forKey key: NSString) {
        let cost = Int(obj.size.width * obj.size.height * 4)
        cache.setObject(obj, forKey: key, cost: cost)
    }
}

private let imageSession: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15
    config.timeoutIntervalForResource = 30
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
    return URLSession(configuration: config)
}()
