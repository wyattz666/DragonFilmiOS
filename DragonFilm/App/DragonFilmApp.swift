import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

enum OrientationManager {
    static func setOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        let target: UIInterfaceOrientationMask
        if orientation == .landscape {
            target = .landscapeRight
        } else {
            target = orientation
        }

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: target)) { _ in }
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

@main
struct DragonFilmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var deepLinkedSlug: String?

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .tint(DFColor.gold)
                .onOpenURL { handleDeepLink($0) }
                .task {
                    await appState.loadProfile()
                }
                .navigationDestination(isPresented: Binding(
                    get: { deepLinkedSlug != nil },
                    set: { if !$0 { deepLinkedSlug = nil } }
                )) {
                    if let slug = deepLinkedSlug {
                        MovieDetailView(slug: slug)
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Supports dragonfilm://movie/{slug} and https://dragonfilm.pages.dev/detail.html?slug={slug}
        if url.scheme == "dragonfilm" {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.first == "movie", let slug = pathComponents.dropFirst().first {
                deepLinkedSlug = slug
            }
        } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let slugItem = (components.queryItems ?? []).first(where: { $0.name == "slug" }),
                  let slug = slugItem.value {
            deepLinkedSlug = slug
        }
    }
}
