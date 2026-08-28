import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        TabView(selection: $state.selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Trang Chủ", systemImage: "house.fill") }
                .tag(AppTab.home)

            NavigationStack { SearchView() }
                .tabItem { Label("Tìm Kiếm", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            NavigationStack { ScheduleView() }
                .tabItem { Label("Lịch Chiếu", systemImage: "calendar") }
                .tag(AppTab.schedule)

            NavigationStack { LibraryView() }
                .tabItem { Label("Thư Viện", systemImage: "books.vertical.fill") }
                .tag(AppTab.library)

            NavigationStack { ProfileView() }
                .tabItem { Label("Cá Nhân", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(DFColor.gold)
        .preferredColorScheme(.dark)
    }
}

enum AppTab: String, CaseIterable {
    case home, search, schedule, library, profile
}

#Preview {
    RootTabView()
        .environment(AppState())
}
