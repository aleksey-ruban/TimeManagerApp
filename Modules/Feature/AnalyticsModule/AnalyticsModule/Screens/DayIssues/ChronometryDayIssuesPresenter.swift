import Foundation

@MainActor
protocol ChronometryDayIssuesView: AnyObject {
    func render(viewModel: ChronometryDayIssuesViewModel)
    func showMessage(_ message: String)
}

@MainActor
final class ChronometryDayIssuesPresenter {
    weak var view: ChronometryDayIssuesView?

    private let service: AnalyticsFeatureServiceProtocol
    private let chronometryID: UUID
    private let date: Date

    init(service: AnalyticsFeatureServiceProtocol, chronometryID: UUID, date: Date) {
        self.service = service
        self.chronometryID = chronometryID
        self.date = date
    }

    func viewDidLoad() {
        reload()
    }
}

private extension ChronometryDayIssuesPresenter {
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

    func makeViewModel(from snapshot: ChronometryDetailSnapshot) -> ChronometryDayIssuesViewModel {
        guard case let .ready(report) = snapshot.analyticsStatus,
              let day = report.daySummaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
            return ChronometryDayIssuesViewModel(
                title: "Проблемы дня",
                subtitle: ChronometryAnalyticsFormatting.dayTitleText(date),
                issueCards: [],
                placeholderText: "Для этого дня ещё нет аналитики"
            )
        }

        return ChronometryDayIssuesViewModel(
            title: "Проблемы дня",
            subtitle: ChronometryAnalyticsFormatting.dayTitleText(day.date),
            issueCards: day.issues.map { issue in
                ChronometryDayIssueCardViewModel(
                    title: ChronometryAnalyticsFormatting.title(for: issue.code),
                    severityText: ChronometryAnalyticsFormatting.severityText(for: issue.severity),
                    severityColor: ChronometryAnalyticsFormatting.severityColor(for: issue.severity),
                    parameterLines: issue.parameters.map(ChronometryAnalyticsFormatting.parameterText),
                    recommendation: issue.recommendation
                )
            },
            placeholderText: day.issues.isEmpty ? "В этот день выраженных проблем не выявлено" : nil
        )
    }
}
