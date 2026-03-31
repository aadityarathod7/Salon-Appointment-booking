import SwiftUI

struct NotificationListView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && notifications.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                        Text("Loading notifications...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("You're all caught up!")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    if !notification.isRead {
                                        Button {
                                            Task { await markAsRead(notification.id) }
                                        } label: {
                                            Label("Read", systemImage: "envelope.open")
                                        }
                                        .tint(.brand)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Notifications")
            .toolbar {
                if !notifications.isEmpty {
                    Button {
                        Task { await markAllRead() }
                    } label: {
                        Text("Read All")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.brand)
                    }
                }
            }
            .task { await loadNotifications() }
            .refreshable { await loadNotifications() }
        }
    }

    func loadNotifications() async {
        isLoading = true
        do {
            let response: ApiResponse<PaginatedResponse<AppNotification>> = try await APIClient.shared.get("/notifications?page=0&size=50")
            notifications = response.data?.content ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markAsRead(_ id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.put("/notifications/\(id)/read")
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let old = notifications[index]
                notifications[index] = AppNotification(
                    id: old.id, title: old.title, body: old.body,
                    type: old.type, referenceId: old.referenceId,
                    isRead: true, sentAt: old.sentAt
                )
            }
        } catch {}
    }

    func markAllRead() async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.put("/notifications/read-all")
            await loadNotifications()
        } catch {}
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification

    var iconName: String {
        switch notification.type {
        case "NEW_BOOKING": return "calendar.badge.plus"
        case "BOOKING_CONFIRMED": return "checkmark.circle.fill"
        case "BOOKING_REJECTED": return "xmark.circle.fill"
        case "BOOKING_CANCELLED": return "xmark.circle.fill"
        case "BOOKING_STARTED": return "play.circle.fill"
        case "BOOKING_COMPLETED": return "star.circle.fill"
        case "BOOKING_RESCHEDULED": return "calendar.badge.clock"
        case "BOOKING_REMINDER": return "clock.fill"
        case "WAITLIST_AVAILABLE": return "bell.badge.fill"
        default: return "bell.fill"
        }
    }

    var iconColor: Color {
        switch notification.type {
        case "NEW_BOOKING": return .brand
        case "BOOKING_CONFIRMED": return .success
        case "BOOKING_REJECTED", "BOOKING_CANCELLED": return .danger
        case "BOOKING_STARTED": return .accent
        case "BOOKING_COMPLETED": return .success
        case "BOOKING_REMINDER": return .warning
        case "WAITLIST_AVAILABLE": return .brand
        default: return .textSecondary
        }
    }

    var timeAgo: String {
        guard let sentAt = notification.sentAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: sentAt) ?? ISO8601DateFormatter().date(from: sentAt) else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let df = DateFormatter()
        df.dateFormat = "dd MMM"
        return df.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.weight(notification.isRead ? .medium : .bold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }

                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(3)
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(notification.isRead ? Color.white : Color.brandLight.opacity(0.15))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}
