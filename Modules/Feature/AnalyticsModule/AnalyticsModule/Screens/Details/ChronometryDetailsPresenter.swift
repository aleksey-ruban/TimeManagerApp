import CommonSync
import Foundation

@MainActor
protocol ChronometryDetailsView: AnyObject {
    func render(viewModel: ChronometryDetailsViewModel)
    func showMessage(_ message: String)
    func presentDeleteConfirmation()
    func presentShareSheet(text: String)
}

@MainActor
final class ChronometryDetailsPresenter {
    weak var view: ChronometryDetailsView?

    private let service: AnalyticsFeatureServiceProtocol
    private let chronometryID: UUID
    private let onOpenRecords: @MainActor (UUID) -> Void
    private let onOpenWeeklyIssue: @MainActor (UUID, ChronometryIssueCode) -> Void
    private let onOpenDayIssues: @MainActor (UUID, Date) -> Void
    private let onDeleted: @MainActor () -> Void
    private let observerBag = NotificationObserverBag()

    private var snapshot: ChronometryDetailSnapshot?

    init(
        service: AnalyticsFeatureServiceProtocol,
        chronometryID: UUID,
        onOpenRecords: @escaping @MainActor (UUID) -> Void,
        onOpenWeeklyIssue: @escaping @MainActor (UUID, ChronometryIssueCode) -> Void,
        onOpenDayIssues: @escaping @MainActor (UUID, Date) -> Void,
        onDeleted: @escaping @MainActor () -> Void
    ) {
        self.service = service
        self.chronometryID = chronometryID
        self.onOpenRecords = onOpenRecords
        self.onOpenWeeklyIssue = onOpenWeeklyIssue
        self.onOpenDayIssues = onOpenDayIssues
        self.onDeleted = onDeleted
    }

    func viewDidLoad() {
        startObservingUpdates()
        reload()
    }

    func viewWillAppear() {
        reload()
    }

    func didTapRecords() {
        onOpenRecords(chronometryID)
    }

    func didTapWeeklyIssue(_ code: ChronometryIssueCode) {
        onOpenWeeklyIssue(chronometryID, code)
    }

    func didTapDayIssues(for date: Date) {
        onOpenDayIssues(chronometryID, date)
    }

    func didTapMenu() {
        view?.presentDeleteConfirmation()
    }

    func confirmDelete() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await service.deleteChronometry(id: chronometryID)
                await MainActor.run {
                    self.view?.showMessage("Хронометраж удалён")
                    self.onDeleted()
                }
            } catch {
                await MainActor.run { self.view?.showMessage(error.localizedDescription) }
            }
        }
    }

    func didTapShare() {
        guard let snapshot else { return }
        view?.presentShareSheet(text: makeShareText(from: snapshot))
    }
}

private extension ChronometryDetailsPresenter {
    func startObservingUpdates() {
        guard observerBag.observers.isEmpty else { return }
        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: AnalyticsFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.reload()
                }
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.reload()
                }
            }
        ]
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await service.loadChronometryDetail(id: chronometryID)
                self.snapshot = snapshot
                await MainActor.run {
                    self.view?.render(viewModel: self.makeViewModel(from: snapshot))
                }
            } catch {
                await MainActor.run { [weak self] in
                    if let serviceError = error as? AnalyticsFeatureServiceError,
                       case .objectNotFound = serviceError {
                        self?.onDeleted()
                    } else {
                        self?.view?.showMessage(error.localizedDescription)
                    }
                }
            }
        }
    }

    func makeViewModel(from snapshot: ChronometryDetailSnapshot) -> ChronometryDetailsViewModel {
        let weeklyRecommendations: [ChronometryWeeklyRecommendationCardViewModel]
        let weeklyPlaceholder: String?
        let dayCards: [ChronometryDaySummaryCardViewModel]
        let dayPlaceholder: String?
        let recommendationBadgeText: String
        let recommendationBadgeStyle: ChronometryHistoryCardViewModel.BadgeStyle
        let summaryText: String

        switch snapshot.analyticsStatus {
        case let .ready(report):
            let weeklyGroups = report.recommendationGroups.filter(\.isWeeklySummary)
            weeklyRecommendations = weeklyGroups.map { group in
                let dayCount = group.dayOccurrences.count
                let canOpenDetails = supportsDayDetails(for: group.code) && dayCount > 0
                return ChronometryWeeklyRecommendationCardViewModel(
                    code: group.code,
                    title: ChronometryAnalyticsFormatting.title(for: group.code),
                    severityText: ChronometryAnalyticsFormatting.severityText(for: group.severity),
                    severityColor: ChronometryAnalyticsFormatting.severityColor(for: group.severity),
                    parameterLines: group.parameters.map(ChronometryAnalyticsFormatting.parameterText),
                    recommendation: group.recommendation,
                    detailButtonTitle: canOpenDetails ? "Просмотреть детали" : nil,
                    detailBadgeText: canOpenDetails ? "\(dayCount)" : nil
                )
            }

            weeklyPlaceholder = weeklyRecommendations.isEmpty ? "По этой записи уже доступна аналитика, но выраженных недельных рекомендаций пока нет" : nil

            dayCards = report.daySummaries.map { day in
                ChronometryDaySummaryCardViewModel(
                    date: day.date,
                    title: ChronometryAnalyticsFormatting.dayTitleText(day.date),
                    metaLines: ChronometryAnalyticsFormatting.dayMetrics(for: day),
                    issueButtonTitle: day.issues.isEmpty ? nil : "Просмотреть проблемы",
                    issueBadgeText: day.issues.isEmpty ? nil : "\(day.issues.count)"
                )
            }
            dayPlaceholder = dayCards.isEmpty ? "Дневная аналитика ещё не подготовлена" : nil

            recommendationBadgeText = report.recommendationCount > 0 ? "\(report.recommendationCount)" : "Данные"
            recommendationBadgeStyle = report.recommendationCount > 0 ? .accent : .neutral
            summaryText = report.recommendationCount > 0
                ? ChronometryAnalyticsFormatting.recommendationsCountText(report.recommendationCount)
                : "Доступна аналитика по записи"

        case .awaitingSync:
            weeklyRecommendations = []
            weeklyPlaceholder = "Аналитика станет доступна после синхронизации"
            dayCards = []
            dayPlaceholder = "Дневная аналитика станет доступна после синхронизации"
            recommendationBadgeText = "…"
            recommendationBadgeStyle = .muted
            summaryText = "Период завершён и ждёт синхронизации"

        case .pendingRemoteFetch:
            weeklyRecommendations = []
            weeklyPlaceholder = "Аналитика загружается из кеша или сервера"
            dayCards = []
            dayPlaceholder = "Дневная аналитика загружается"
            recommendationBadgeText = "…"
            recommendationBadgeStyle = .muted
            summaryText = "Аналитика по периоду подгружается"
        }

        return ChronometryDetailsViewModel(
            periodTitle: ChronometryAnalyticsFormatting.periodText(
                from: snapshot.chronometry.startDate,
                to: snapshot.chronometry.endDate
            ),
            summaryText: summaryText,
            recommendationBadgeText: recommendationBadgeText,
            recommendationBadgeStyle: recommendationBadgeStyle,
            recordsCard: makeRecordsCard(from: snapshot),
            weeklyRecommendationsTitle: "Рекомендации недели",
            weeklyRecommendations: weeklyRecommendations,
            weeklyRecommendationsPlaceholder: weeklyPlaceholder,
            daySummariesTitle: "Дни записи",
            daySummaries: dayCards,
            daySummariesPlaceholder: dayPlaceholder
        )
    }

    func makeRecordsCard(from snapshot: ChronometryDetailSnapshot) -> ChronometryRecordsCardViewModel {
        let recordsCount = snapshot.activityTimelineEntries.count
        let categories = Set(snapshot.activityTimelineEntries.compactMap(\.categoryName)).count
        let activities = Set(snapshot.activityTimelineEntries.map(\.activityName)).count

        return ChronometryRecordsCardViewModel(
            title: "Данные записи",
            subtitle: recordsCount > 0
                ? "Внутри вся хронология активности по периоду"
                : "Хронология будет доступна, когда в периоде появятся записи",
            metaLines: [
                "\(recordsCount) записей активности",
                "\(activities) активностей и \(categories) категорий"
            ],
            buttonTitle: "Открыть хронологию"
        )
    }

    func supportsDayDetails(for code: ChronometryIssueCode) -> Bool {
        switch code {
        case .noDaysOff, .irregularSleep:
            return false
        case .lowFocus,
                .noBreaks,
                .tooManyTaskSwitches,
                .excessiveMultitasking,
                .fragmentedWorkday,
                .longWorkday,
                .insufficientSleep:
            return true
        }
    }

    func makeShareText(from snapshot: ChronometryDetailSnapshot) -> String {
        let header = "Хронометраж \(ChronometryAnalyticsFormatting.periodText(from: snapshot.chronometry.startDate, to: snapshot.chronometry.endDate))"

        switch snapshot.analyticsStatus {
        case let .ready(report):
            let summary = report.recommendationCount > 0
                ? ChronometryAnalyticsFormatting.recommendationsCountText(report.recommendationCount)
                : "Доступна аналитика по записи"
            return [header, summary].joined(separator: "\n")
        case .awaitingSync:
            return [header, "Аналитика станет доступна после синхронизации"].joined(separator: "\n")
        case .pendingRemoteFetch:
            return [header, "Аналитика по периоду загружается"].joined(separator: "\n")
        }
    }
}
