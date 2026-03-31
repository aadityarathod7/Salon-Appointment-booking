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

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(.brand)
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

            AdminReportsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "chart.bar.fill" : "chart.bar")
                    Text("Reports")
                }
                .tag(4)
        }
        .tint(.brand)
    }
}
