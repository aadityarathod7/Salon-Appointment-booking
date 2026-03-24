import SwiftUI

struct NotificationListView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if notifications.isEmpty {
                    ContentUnavailableView("No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up!"))
                } else {
                    List(notifications) { notification in
                        HStack(spacing: 12) {
                            Image(systemName: notificationIcon(notification.type))
                                .foregroundColor(.brand)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.headline)
                                    .foregroundColor(notification.isRead ? .secondary : .primary)
                                Text(notification.body)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                Button("Mark All Read") {
                    Task { await markAllRead() }
                }
            }
            .task { await loadNotifications() }
            .refreshable { await loadNotifications() }
        }
    }

    func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: ApiResponse<PaginatedResponse<AppNotification>> = try await APIClient.shared.get("/notifications?page=0&size=50")
            notifications = response.data?.content ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markAllRead() async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.put("/notifications/read-all")
            await loadNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func notificationIcon(_ type: String) -> String {
        switch type {
        case "BOOKING_CONFIRMED": return "checkmark.circle.fill"
        case "BOOKING_REMINDER": return "clock.fill"
        case "BOOKING_CANCELLED": return "xmark.circle.fill"
        case "WAITLIST_AVAILABLE": return "bell.badge.fill"
        default: return "bell.fill"
        }
    }
}
