import SwiftUI

struct AdminServicesView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var showAddService = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.services) { service in
                        AdminServiceCard(service: service) {
                            Task { await vm.deleteService(id: service.id) }
                        }
                    }
                }
                .padding()
            }
            .background(Color.surfaceBg)
            .navigationTitle("Services")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddService = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brand)
                    }
                }
            }
            .sheet(isPresented: $showAddService) {
                AddServiceView { Task { await vm.loadServices() } }
            }
            .overlay {
                if vm.services.isEmpty && !vm.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "scissors.badge.ellipsis")
                            .font(.system(size: 44))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text("No services found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .task {
                await vm.loadServices()
            }
            .refreshable {
                await vm.loadServices()
            }
        }
    }
}

struct AdminServiceCard: View {
    let service: SalonService
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 14) {
            // Image
            if let img = service.imageUrl, !img.isEmpty {
                Image(img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brandLight.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "scissors")
                            .foregroundColor(.brand)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 10) {
                    Label("\(service.durationMinutes)m", systemImage: "clock")
                    if let cat = service.category {
                        Label(cat, systemImage: "tag")
                    }
                }
                .font(.caption)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("₹\(Int(service.price))")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.brand)

                VStack(spacing: 8) {
                    Button {
                        showEdit = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.brand)
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.danger)
                    }
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .sheet(isPresented: $showEdit) {
            EditServiceView(service: service) { onDelete() }
        }
        .confirmationDialog("Deactivate \(service.name)?", isPresented: $showDeleteConfirm) {
            Button("Deactivate", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
