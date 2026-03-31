import SwiftUI

struct AdminReportsView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var selectedPeriod = 0

    let periods = ["Last 7 Days", "Last 30 Days", "Last 90 Days"]

    var startDate: Date {
        let days: [Int] = [7, 30, 90]
        return Date().addingTimeInterval(-Double(days[selectedPeriod]) * 24 * 3600)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(0..<periods.count, id: \.self) { i in
                            Text(periods[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, _ in
                        Task { await vm.loadRevenueReport(startDate: startDate) }
                    }

                    if let report = vm.revenueReport {
                        // Total Revenue Card
                        VStack(spacing: 8) {
                            Text("Total Revenue")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            Text("₹\(Int(report.totalRevenue))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.brand)
                            Text(report.period)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        .padding(.horizontal)

                        // Revenue Breakdown
                        if !report.breakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Daily Breakdown")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.textPrimary)

                                // Bar chart
                                let maxRevenue = report.breakdown.map(\.revenue).max() ?? 1

                                ForEach(report.breakdown) { item in
                                    HStack(spacing: 10) {
                                        Text(formatDate(item.date))
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.textSecondary)
                                            .frame(width: 55, alignment: .leading)

                                        GeometryReader { geo in
                                            let barWidth = max(CGFloat(item.revenue / maxRevenue) * geo.size.width, 4)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.brand, .brandLight],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: barWidth, height: 22)
                                        }
                                        .frame(height: 22)

                                        Text("₹\(Int(item.revenue))")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.textPrimary)
                                            .frame(width: 55, alignment: .trailing)
                                    }
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 44))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                Text("No revenue data for this period")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }
                    } else if vm.isLoading {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 80)
                            ProgressView()
                            Text("Loading reports...")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.surfaceBg)
            .navigationTitle("Reports")
            .task {
                await vm.loadRevenueReport(startDate: startDate)
            }
        }
    }

    func formatDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[2])/\(parts[1])"
        }
        return dateStr
    }
}
