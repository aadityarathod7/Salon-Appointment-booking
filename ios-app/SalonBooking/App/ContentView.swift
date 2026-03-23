import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            ServiceListView()
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Services")
                }

            AppointmentListView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Bookings")
                }

            NotificationListView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Alerts")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .tint(.purple)
    }
}
