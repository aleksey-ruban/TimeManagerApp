import Foundation

@MainActor
protocol ChronometryRecordTimelineView: AnyObject {
    func render(viewModel: ChronometryRecordTimelineViewModel)
    func showMessage(_ message: String)
}

@MainActor
final class ChronometryRecordTimelinePresenter {
    weak var view: ChronometryRecordTimelineView?

    private let service: AnalyticsFeatureServiceProtocol
    private let chronometryID: UUID

    init(service: AnalyticsFeatureServiceProtocol, chronometryID: UUID) {
        self.service = service
        self.chronometryID = chronometryID
    }

    func viewDidLoad() {
        reload()
    }
}

private extension ChronometryRecordTimelinePresenter {
    func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await service.loadChronometryDetail(id: chronometryID)
                await MainActor.run {
                    self.view?.render(viewModel: self.makeViewModel(from: snapshot))
                }
            } catch {
                await MainActor.run { self.view?.showMessage(error.localizedDescription) }
            }
        }
    }

    func makeViewModel(from snapshot: ChronometryDetailSnapshot) -> ChronometryRecordTimelineViewModel {
        let grouped = Dictionary(grouping: snapshot.activityTimelineEntries) { entry in
            Calendar.current.startOfDay(for: entry.startedAt)
        }
        let sortedDates = grouped.keys.sorted()
        let sections = sortedDates.map { date in
            ChronometryRecordTimelineSectionViewModel(
                title: ChronometryAnalyticsFormatting.dayTitleText(date),
                entries: (grouped[date] ?? []).map { entry in
                    ChronometryRecordTimelineEntryViewModel(
                        title: entry.activityName,
                        subtitle: [entry.categoryName, entry.variationName]
                            .compactMap { $0 }
                            .joined(separator: " • "),
                        timeRange: ChronometryAnalyticsFormatting.timeRangeText(
                            startedAt: entry.startedAt,
                            endedAt: entry.endedAt
                        ),
                        iconName: entry.iconName,
                        tintColor: entry.color
                    )
                }
            )
        }

        return ChronometryRecordTimelineViewModel(
            title: "Хронология записи",
            subtitle: sections.isEmpty
                ? "Записей активности пока нет"
                : "\(snapshot.activityTimelineEntries.count) записей активности",
            sections: sections,
            placeholderText: sections.isEmpty ? "Внутри этого периода пока нет записей активности" : nil
        )
    }
}
