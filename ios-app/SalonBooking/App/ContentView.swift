import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.currentUser?.role == "ADMIN" {
                    AdminTabView()
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var unreadCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            ServiceListView()
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Services")
                }
                .tag(1)

            AppointmentListView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "calendar.circle.fill" : "calendar")
                    Text("Bookings")
                }
                .tag(2)

            NotificationListView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bell.fill" : "bell")
                    Text("Alerts")
                }
                .tag(3)
                .badge(unreadCount)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.brand)
        .task {
            await loadUnreadCount()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 3 {
                // Refresh count when leaving alerts tab
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await loadUnreadCount()
                }
            } else {
                Task { await loadUnreadCount() }
            }
        }
    }

    func loadUnreadCount() async {
        do {
            let response: ApiResponse<PaginatedResponse<AppNotification>> = try await APIClient.shared.get("/notifications?size=100")
            unreadCount = response.data?.content.filter { !$0.isRead }.count ?? 0
        } catch {
            unreadCount = 0
        }
    }
}

struct AdminTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Dashboard")
                }
                .tag(0)

            AdminAppointmentsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "calendar.circle.fill" : "calendar")
                    Text("Bookings")
                }
                .tag(1)

            AdminArtistsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.2.fill" : "person.2")
                    Text("Artists")
                }
                .tag(2)

            AdminServicesView()
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Services")
                }
                .tag(3)

            NotificationListView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "bell.fill" : "bell")
                    Text("Alerts")
                }
                .tag(4)

            AdminReportsView()
                .tabItem {
                    Image(systemName: selectedTab == 5 ? "chart.bar.fill" : "chart.bar")
                    Text("Reports")
                }
                .tag(5)
        }
        .tint(.brand)
    }
}
