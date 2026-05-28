import SwiftUI

struct StatsSheet: View {
    @Bindable var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        Text("Yükleniyor...")
                            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else {
                        if viewModel.summary.count > 0 {
                            summaryCards
                        }

                        if viewModel.fastingHistory.isEmpty {
                            Text("Henüz tamamlanan oruç yok")
                                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                        } else {
                            fastingList
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .glassSheetBackground()
    }

    private var summaryCards: some View {
        AdaptiveGlassContainer {
            HStack(spacing: 8) {
                summaryCard(title: "Toplam", value: "\(viewModel.summary.count)")
                summaryCard(
                    title: "En uzun",
                    value: FastingHistory.formatDuration(hours: viewModel.summary.longestHours),
                    accent: true
                )
                summaryCard(
                    title: "En kısa",
                    value: FastingHistory.formatDuration(hours: viewModel.summary.shortestHours),
                    amber: true
                )
            }
        }
    }

    private func summaryCard(title: String, value: String, accent: Bool = false, amber: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            Text(value)
                .font(.system(size: accent ? 18 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    accent ? AppTheme.accent(for: colorScheme) :
                        amber ? Color.orange : .primary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassPanel(cornerRadius: 14)
    }

    private var fastingList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.fastingHistory) { record in
                fastingRow(record)
            }
        }
    }

    private func fastingRow(_ record: FastingRecord) -> some View {
        let completion = viewModel.completion(for: record)
        let barColor = FastingColor.color(fromRatio: completion.fillRatio)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(FastingHistory.formatDuration(hours: record.durationHours))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Text("%\(completion.percent)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(barColor)
            }

            Text(FastingHistory.formatTimeRange(start: record.start, end: record.end))
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Hedef: \(viewModel.targetLabel)")
                    Spacer()
                    Text("%\(completion.percent) tamamlandı")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            stops: FastingColor.gradientStops(),
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        Rectangle()
                            .fill(AppTheme.surfaceElevated(for: colorScheme))
                            .frame(width: geometry.size.width * (1 - min(completion.fillRatio, 1)))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 14)
    }
}

#Preview {
    StatsSheet(viewModel: StatsViewModel())
}
