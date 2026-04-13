import CommonSync
import Foundation

@MainActor
protocol ChronometryDashboardView: AnyObject {
    func render(viewModel: ChronometryDashboardViewModel)
    func showMessage(_ message: String)
    func presentDeleteConfirmation()
}

@MainActor
final class ChronometryDashboardPresenter {
    weak var view: ChronometryDashboardView?

    private let service: AnalyticsFeatureServiceProtocol
    private let onOpenChronometry: @MainActor (UUID) -> Void
    private let observerBag = NotificationObserverBag()

    private var snapshot = AnalyticsFeatureSnapshot(
        controlState: .readyToStart(
            ReadyToStartState(
                suggestedFirstDay: Date(),
                startsToday: true
            )
        ),
        historyItems: []
    )

    init(
        service: AnalyticsFeatureServiceProtocol,
        onOpenChronometry: @escaping @MainActor (UUID) -> Void
    ) {
        self.service = service
        self.onOpenChronometry = onOpenChronometry
    }

    func viewDidLoad() {
        startObservingUpdates()
        reload()
        refreshAnalytics()
    }

    func viewWillAppear() {
        reload()
        refreshAnalytics()
    }

    func didTapPrimaryAction(_ action: ChronometryControlCardViewModel.PrimaryAction) {
        Task { [weak self] in
            guard let self else { return }
            do {
                switch action {
                case .start:
                    try await service.startChronometry(force: false)
                    await MainActor.run { self.view?.showMessage("Хронометраж начат") }
                case .forceStart:
                    try await service.startChronometry(force: true)
                    await MainActor.run { self.view?.showMessage("Хронометраж начат раньше рекомендованной даты") }
                case .finish:
                    try await service.finishActiveChronometry()
                    await MainActor.run { self.view?.showMessage("Хронометраж завершён, аналитика появится после синхронизации") }
                case .none:
                    return
                }
                await MainActor.run { self.reload() }
            } catch {
                await MainActor.run { self.view?.showMessage(error.localizedDescription) }
            }
        }
    }

    func didTapControlMenu() {
        guard canDeleteActiveChronometry else { return }
        view?.presentDeleteConfirmation()
    }

    func confirmDeleteActiveChronometry() {
        deleteCurrentActiveChronometry()
    }

    func didTapHistoryCard(id: UUID) {
        onOpenChronometry(id)
    }
}

private extension ChronometryDashboardPresenter {
    var canDeleteActiveChronometry: Bool {
        switch snapshot.controlState {
        case .inProgress, .readyToFinish:
            return true
        case .readyToStart, .cooldown:
            return false
        }
    }

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
                    self?.refreshAnalytics()
                }
            }
        ]
    }

    func reload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                snapshot = try await service.loadSnapshotAsync()
                await MainActor.run { self.render() }
            } catch {
                await MainActor.run { self.view?.showMessage(error.localizedDescription) }
            }
        }
    }

    func refreshAnalytics() {
        Task { [weak self] in
            guard let self else { return }
            await service.refreshAnalyticsIfNeeded()
        }
    }

    func render() {
        view?.render(
            viewModel: ChronometryDashboardViewModel(
                controlCard: makeControlCardViewModel(snapshot.controlState),
                historySectionTitle: "Прошлые хронометражи",
                historyCards: snapshot.historyItems.map(makeHistoryCardViewModel),
                emptyHistoryText: "Завершённых хронометражей пока нет"
            )
        )
    }

    func makeControlCardViewModel(_ state: ChronometryControlState) -> ChronometryControlCardViewModel {
        switch state {
        case let .readyToStart(readyState):
            return ChronometryControlCardViewModel(
                title: "Новый хронометраж",
                subtitle: "Соберите спокойную неделю наблюдений и получите понятную аналитику с рекомендациями",
                metaLines: [
                    readyState.startsToday ? "Первым днём записи станет сегодня" : "Первым днём записи станет завтра",
                    "Период займёт 7 дней"
                ],
                tipText: readyState.startsToday
                    ? "Если начать до 9:00 по местному времени, запись начнётся с сегодняшнего дня"
                    : "Если начать после 9:00, запись автоматически начнётся с завтрашнего дня",
                primaryActionTitle: "Начать хронометраж",
                primaryAction: .start,
                showsMenu: false
            )

        case let .inProgress(activeState):
            return ChronometryControlCardViewModel(
                title: activeState.isScheduled ? "Старт уже запланирован" : "Идёт запись",
                subtitle: activeState.isScheduled
                    ? "Первый день начнётся автоматически, дальше просто живите в обычном ритме"
                    : "Мы собираем картину вашей недели, ничего дополнительно делать не нужно",
                metaLines: [
                    "Записано \(activeState.recordedDays) из 7 дней",
                    "Осталось \(activeState.remainingDays) дней",
                    "Последний день \(ChronometryAnalyticsFormatting.fullDateText(activeState.lastDay))"
                ],
                tipText: "При необходимости хронометраж можно удалить через меню",
                primaryActionTitle: nil,
                primaryAction: .none,
                showsMenu: true
            )

        case let .readyToFinish(activeState):
            return ChronometryControlCardViewModel(
                title: "Можно завершить",
                subtitle: "Неделя собрана, теперь можно получить аналитику и рекомендации",
                metaLines: [
                    "Записано \(activeState.recordedDays) из 7 дней",
                    "Последний день \(ChronometryAnalyticsFormatting.fullDateText(activeState.lastDay))",
                    "Завершение уже доступно"
                ],
                tipText: "Если передумали, хронометраж можно удалить через меню",
                primaryActionTitle: "Завершить хронометраж",
                primaryAction: .finish,
                showsMenu: true
            )

        case let .cooldown(cooldownState):
            return ChronometryControlCardViewModel(
                title: "Новый период можно запускать позже",
                subtitle: "Так аналитика по следующей неделе получится точнее и полезнее",
                metaLines: [
                    "Рекомендуемый старт после \(ChronometryAnalyticsFormatting.fullDateText(cooldownState.recommendedStartDate))",
                    "При желании новый период можно запустить раньше"
                ],
                tipText: "Форсированный запуск доступен в любой момент",
                primaryActionTitle: "Начать раньше",
                primaryAction: .forceStart,
                showsMenu: false
            )
        }
    }

    func makeHistoryCardViewModel(_ item: ChronometryHistoryItem) -> ChronometryHistoryCardViewModel {
        ChronometryHistoryCardViewModel(
            id: item.chronometry.localID,
            periodTitle: ChronometryAnalyticsFormatting.periodText(
                from: item.chronometry.startDate,
                to: item.chronometry.endDate
            ),
            summaryText: ChronometryAnalyticsFormatting.historySummaryText(for: item.analyticsStatus),
            badgeText: ChronometryAnalyticsFormatting.historyBadgeText(for: item.analyticsStatus),
            badgeStyle: ChronometryAnalyticsFormatting.historyBadgeStyle(for: item.analyticsStatus)
        )
    }

    func deleteCurrentActiveChronometry() {
        let activeID: UUID
        switch snapshot.controlState {
        case let .inProgress(activeState), let .readyToFinish(activeState):
            activeID = activeState.chronometryID
        case .readyToStart, .cooldown:
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await service.deleteChronometry(id: activeID)
                await MainActor.run {
                    self.view?.showMessage("Хронометраж удалён")
                    self.reload()
                }
            } catch {
                await MainActor.run { self.view?.showMessage(error.localizedDescription) }
            }
        }
    }
}
