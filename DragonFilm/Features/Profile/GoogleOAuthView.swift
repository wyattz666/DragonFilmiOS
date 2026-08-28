import SwiftUI
import WebKit

struct GoogleOAuthView: View {
    @Environment(\.dismiss) private var dismiss
    let onAuthSuccess: (String?, String?) -> Void
    let onAuthFailure: (String) -> Void

    @State private var isLoading = true
    @State private var progress: Double = 0.0

    private var startURL: URL {
        URL(string: "\(APIClient.shared.baseURL)/api/auth/oauth/google/start?provider=google&returnTo=%2Findex.html")
            ?? URL(string: "https://dragonfilm.pages.dev/api/auth/oauth/google/start?provider=google&returnTo=%2Findex.html")!
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                DFColor.bg.ignoresSafeArea()

                GoogleOAuthWebView(
                    url: startURL,
                    isLoading: $isLoading,
                    progress: $progress,
                    onTokenFound: { token, accessToken in
                        dismiss()
                        onAuthSuccess(token, accessToken)
                    },
                    onErrorFound: { errorMsg in
                        dismiss()
                        onAuthFailure(errorMsg)
                    }
                )

                if isLoading {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: DFColor.gold))
                        .frame(height: 2)
                        .background(Color.white.opacity(0.1))
                }
            }
            .navigationTitle("Đăng Nhập Google")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .font(DFFont.body())
                    .foregroundStyle(DFColor.goldDim)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct GoogleOAuthWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var progress: Double
    let onTokenFound: (String?, String?) -> Void
    let onErrorFound: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // Standard mobile Safari user agent to prevent Google OAuth restriction
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"
        webView.backgroundColor = UIColor(DFColor.bg)
        webView.isOpaque = false
        
        context.coordinator.setupObservation(for: webView)
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: GoogleOAuthWebView
        private var observation: NSKeyValueObservation?
        private var tokenHandled = false

        init(parent: GoogleOAuthWebView) {
            self.parent = parent
        }

        func setupObservation(for webView: WKWebView) {
            observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.progress = webView.estimatedProgress
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            if let currentURL = webView.url {
                checkAuthFromURL(currentURL)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let reqURL = navigationAction.request.url {
                if checkAuthFromURL(reqURL) {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            guard !tokenHandled, let currentURL = webView.url else { return }
            
            if checkAuthFromURL(currentURL) {
                return
            }

            // Check localStorage and hash on dragonfilm domain
            if currentURL.host?.contains("dragonfilm") == true {
                let js = """
                (function() {
                    try {
                        var h = window.location.hash || '';
                        var t = localStorage.getItem('dragonfilm_auth_token') || '';
                        return JSON.stringify({ hash: h, token: t });
                    } catch(e) {
                        return '';
                    }
                })()
                """
                webView.evaluateJavaScript(js) { [weak self] result, _ in
                    guard let self, !self.tokenHandled, let jsonString = result as? String,
                          let data = jsonString.data(using: .utf8),
                          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
                    else { return }

                    if let hash = dict["hash"], !hash.isEmpty {
                        let parsed = self.parseParams(from: hash.replacingOccurrences(of: "^#", with: "", options: .regularExpression))
                        if let token = parsed["oauth_token"] ?? parsed["token"], !token.isEmpty {
                            self.tokenHandled = true
                            DispatchQueue.main.async {
                                self.parent.onTokenFound(token, nil)
                            }
                            return
                        }
                        if let accessToken = parsed["access_token"], !accessToken.isEmpty {
                            self.tokenHandled = true
                            DispatchQueue.main.async {
                                self.parent.onTokenFound(nil, accessToken)
                            }
                            return
                        }
                    }

                    if let storedToken = dict["token"], !storedToken.isEmpty {
                        self.tokenHandled = true
                        DispatchQueue.main.async {
                            self.parent.onTokenFound(storedToken, nil)
                        }
                    }
                }
            }
        }

        @discardableResult
        private func checkAuthFromURL(_ url: URL) -> Bool {
            guard !tokenHandled else { return true }
            
            // 1. Check fragment (#oauth_token=... or #access_token=...)
            if let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment {
                let params = parseParams(from: fragment)
                if let err = params["oauth_error"] ?? params["error_description"] ?? params["error"] {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onErrorFound(err)
                    }
                    return true
                }
                if let token = params["oauth_token"] ?? params["token"], !token.isEmpty {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onTokenFound(token, nil)
                    }
                    return true
                }
                if let accessToken = params["access_token"], !accessToken.isEmpty {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onTokenFound(nil, accessToken)
                    }
                    return true
                }
            }

            // 2. Check query params (?oauth_token=... or ?access_token=...)
            if let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.query {
                let params = parseParams(from: query)
                if let err = params["oauth_error"] ?? params["error_description"] ?? params["error"] {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onErrorFound(err)
                    }
                    return true
                }
                if let token = params["oauth_token"] ?? params["token"], !token.isEmpty {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onTokenFound(token, nil)
                    }
                    return true
                }
                if let accessToken = params["access_token"], !accessToken.isEmpty {
                    tokenHandled = true
                    DispatchQueue.main.async {
                        self.parent.onTokenFound(nil, accessToken)
                    }
                    return true
                }
            }

            return false
        }

        private func parseParams(from string: String) -> [String: String] {
            var params: [String: String] = [:]
            for pair in string.split(separator: "&") {
                let parts = pair.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0])
                    let val = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                    params[key] = val
                }
            }
            return params
        }
    }
}
