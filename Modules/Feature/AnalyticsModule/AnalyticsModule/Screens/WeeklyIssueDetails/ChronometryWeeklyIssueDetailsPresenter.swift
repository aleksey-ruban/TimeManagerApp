import Foundation

@MainActor
protocol ChronometryWeeklyIssueDetailsView: AnyObject {
    func render(viewModel: ChronometryWeeklyIssueDetailsViewModel)
    func showMessage(_ message: String)
}

@MainActor
final class ChronometryWeeklyIssueDetailsPresenter {
    weak var view: ChronometryWeeklyIssueDetailsView?

    private let service: AnalyticsFeatureServiceProtocol
    private let chronometryID: UUID
    private let code: ChronometryIssueCode

    init(service: AnalyticsFeatureServiceProtocol, chronometryID: UUID, code: ChronometryIssueCode) {
        self.service = service
        self.chronometryID = chronometryID
        self.code = code
    }

    func viewDidLoad() {
        reload()
    }
}

private extension ChronometryWeeklyIssueDetailsPresenter {
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

    func makeViewModel(from snapshot: ChronometryDetailSnapshot) -> ChronometryWeeklyIssueDetailsViewModel {
        guard case let .ready(report) = snapshot.analyticsStatus,
              let group = report.recommendationGroups.first(where: { $0.isWeeklySummary && $0.code == code }) else {
            return ChronometryWeeklyIssueDetailsViewModel(
                title: ChronometryAnalyticsFormatting.title(for: code),
                subtitle: "Детали пока недоступны",
                severityText: "",
                severityColor: .clear,
                parameterLines: [],
                recommendation: "",
                dayCards: [],
                placeholderText: "По этой рекомендации пока нет данных по дням"
            )
        }

        return ChronometryWeeklyIssueDetailsViewModel(
            title: ChronometryAnalyticsFormatting.title(for: code),
            subtitle: ChronometryAnalyticsFormatting.periodText(
                from: snapshot.chronometry.startDate,
                to: snapshot.chronometry.endDate
            ),
            severityText: ChronometryAnalyticsFormatting.severityText(for: group.severity),
            severityColor: ChronometryAnalyticsFormatting.severityColor(for: group.severity),
            parameterLines: group.parameters.map(ChronometryAnalyticsFormatting.parameterText),
            recommendation: group.recommendation,
            dayCards: group.dayOccurrences.map {
                ChronometryIssueDayCardViewModel(
                    title: ChronometryAnalyticsFormatting.dayTitleText($0.date),
                    subtitle: ChronometryAnalyticsFormatting.severityText(for: $0.severity),
                    parameterLines: $0.parameters.map(ChronometryAnalyticsFormatting.parameterText)
                )
            },
            placeholderText: group.dayOccurrences.isEmpty ? "По этой рекомендации нет отдельных дневных проявлений" : nil
        )
    }
}
