import UIKit
import CommonSync
import DesignTokens
import Domain
import Foundation

@MainActor
protocol ActivityOverviewView: AnyObject {
    func render(viewModel: ActivityOverviewViewModel)
    func presentCalendar(selectedDate: Date, highlightedDates: Set<Date>, onSelectDate: @escaping (Date) -> Void)
}

@MainActor
final class ActivityOverviewPresenter {
    weak var view: ActivityOverviewView?

    private let service: ActivitiesFeatureServiceProtocol
    private let onCreateRecord: () -> Void
    private let onEditRecord: (UUID) -> Void
    private let nowProvider: @Sendable () -> Date
    private let observerBag = NotificationObserverBag()

    private var refreshTimer: Timer?
    private var selectedDate: Date
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var activityRecords: [ActivityRecord] = []

    private let palette: [UIColor] = [
        UIColor(red: 0.17, green: 0.55, blue: 0.84, alpha: 1),
        UIColor(red: 0.96, green: 0.58, blue: 0.18, alpha: 1),
        UIColor(red: 0.30, green: 0.69, blue: 0.37, alpha: 1),
        UIColor(red: 0.85, green: 0.34, blue: 0.49, alpha: 1),
        UIColor(red: 0.46, green: 0.42, blue: 0.85, alpha: 1),
        UIColor(red: 0.10, green: 0.63, blue: 0.58, alpha: 1),
        UIColor(red: 0.79, green: 0.49, blue: 0.20, alpha: 1),
        UIColor(red: 0.55, green: 0.43, blue: 0.36, alpha: 1),
    ]
    init(
        service: ActivitiesFeatureServiceProtocol,
        onCreateRecord: @escaping () -> Void,
        onEditRecord: @escaping (UUID) -> Void,
        nowProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.service = service
        self.onCreateRecord = onCreateRecord
        self.onEditRecord = onEditRecord
        self.nowProvider = nowProvider
        self.selectedDate = nowProvider()
    }

    func viewDidLoad() {
        startObservingUpdates()
        reloadFromSource()
    }

    func viewWillAppear() {
        reloadFromSource()
        startRefreshTimer()
    }

    func viewDidDisappear() {
        stopRefreshTimer()
    }

    func didTapAddRecord() {
        onCreateRecord()
    }

    func didTapPreviousDate() {
        shiftSelectedDate(by: -1)
    }

    func didTapNextDate() {
        shiftSelectedDate(by: 1)
    }

    func didTapDate() {
        view?.presentCalendar(
            selectedDate: selectedDate,
            highlightedDates: makeHighlightedDates(),
            onSelectDate: { [weak self] date in
                self?.selectedDate = date
                self?.reload()
            }
        )
    }

    func didTapActiveItem(id: UUID) {
        Task { [weak self] in
            guard let self else { return }
            _ = try? await service.stopActivityRecord(id: id, endedAt: nowProvider())
            reloadFromSource()
        }
    }

    func didSelectRecord(at index: Int) {
        let items = makeRecordItems()
        guard items.indices.contains(index) else { return }
        onEditRecord(items[index].id)
    }

    func didDeleteRecord(at index: Int) {
        let items = makeRecordItems()
        guard items.indices.contains(index) else { return }

        let recordID = items[index].id
        Task { [weak self] in
            guard let self else { return }
            try? await service.deleteActivityRecord(id: recordID)
            reloadFromSource()
        }
    }
}

private extension ActivityOverviewPresenter {
    func startObservingUpdates() {
        guard observerBag.observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: ActivitiesFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromSource()
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reloadFromSource()
            }
        ]
    }

    func startRefreshTimer() {
        guard refreshTimer == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromSource()
            }
        }
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func shiftSelectedDate(by days: Int) {
        guard let updatedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = updatedDate
        reload()
    }

    func reloadFromSource() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await service.loadSnapshotAsync()
                categories = snapshot.categories
                activities = snapshot.activities
                activityRecords = snapshot.activityRecords
            } catch {
                categories = []
                activities = []
                activityRecords = []
            }

            reload()
        }
    }

    func reload() {
        let categoryItems = makeCategoryItems()
        let chart = makeChartSummary(categoryItems: categoryItems)

        view?.render(
            viewModel: ActivityOverviewViewModel(
                selectedDate: selectedDate,
                activeItems: shouldShowActiveItems ? makeActiveItems() : [],
                chartSegments: chart.chartSegments,
                chartSummary: chart.chartSummary,
                categoryItems: categoryItems,
                recordItems: makeRecordItems()
            )
        )
    }

    func selectedDayRange() -> (start: Date, end: Date)? {
        let start = Calendar.current.startOfDay(for: selectedDate)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return nil }
        return (start, end)
    }

    func makeActiveItems() -> [ActivityOverviewActiveItemViewModel] {
        activityRecords
            .filter { $0.endedAt == nil && $0.isDeleted == false }
            .sorted { $0.startedAt > $1.startedAt }
            .compactMap { record in
                guard let activity = activity(id: record.activityLocalID) else { return nil }
                return ActivityOverviewActiveItemViewModel(
                    id: record.localID,
                    activity: activity,
                    categoryName: category(id: activity.categoryLocalID)?.baseName,
                    startedAt: record.startedAt
                )
            }
    }

    func makeRecordItems() -> [ActivityOverviewRecordItemViewModel] {
        guard let range = selectedDayRange() else { return [] }

        return activityRecords
            .filter { record in
                guard record.isDeleted == false else { return false }
                let endDate = record.endedAt ?? nowProvider()
                return record.startedAt < range.end && endDate > range.start
            }
            .sorted { $0.startedAt > $1.startedAt }
            .compactMap { record -> ActivityOverviewRecordItemViewModel? in
                guard let activity = activity(id: record.activityLocalID) else { return nil }
                let categoryName = category(id: activity.categoryLocalID)?.baseName
                let duration = max(0, clippedDuration(for: record, startOfDay: range.start, endOfDay: range.end))
                let categoryPart = (categoryName?.isEmpty == false ? categoryName! + " • " : "")
                return ActivityOverviewRecordItemViewModel(
                    id: record.localID,
                    title: activity.name,
                    subtitle: "\(categoryPart)\(formattedTime(record.startedAt)) - \(formattedTime(record.endedAt))",
                    duration: formattedDuration(duration),
                    iconName: activity.iconName,
                    iconColor: activity.color.uiColor
                )
            }
    }

    func makeCategoryItems() -> [ActivityOverviewCategoryItemViewModel] {
        guard let range = selectedDayRange() else { return [] }

        var durationByTitle: [String: TimeInterval] = [:]
        var countByTitle: [String: Int] = [:]

        for record in activityRecords where record.isDeleted == false {
            let endDate = record.endedAt ?? nowProvider()
            guard record.startedAt < range.end && endDate > range.start else { continue }

            let duration = clippedDuration(for: record, startOfDay: range.start, endOfDay: range.end)
            guard duration > 0 else { continue }

            let title = categoryTitle(for: record.activityLocalID)
            durationByTitle[title, default: 0] += duration
            countByTitle[title, default: 0] += 1
        }

        let sorted = durationByTitle
            .map { (title: $0.key, duration: $0.value, count: countByTitle[$0.key, default: 0]) }
            .sorted {
                if $0.duration == $1.duration {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.duration > $1.duration
            }

        return sorted.enumerated().map { index, item in
            let countTitle = recordCountTitle(item.count)
            return ActivityOverviewCategoryItemViewModel(
                title: item.title,
                subtitle: "\(formattedDuration(item.duration)) • \(item.count) \(countTitle)",
                duration: item.duration,
                color: palette[index % palette.count]
            )
        }
    }

    func makeChartSummary(categoryItems: [ActivityOverviewCategoryItemViewModel]) -> (chartSegments: [ActivityOverviewChartSegmentViewModel], chartSummary: String) {
        let totalDuration = categoryItems.reduce(0) { $0 + $1.duration }
        guard totalDuration > 0 else {
            return (
                [ActivityOverviewChartSegmentViewModel(value: 1, color: DesignColor.backgroundSecondary)],
                "За выбранный день нет данных"
            )
        }

        let chartItems = categoryItems.map {
            ActivityOverviewChartSegmentViewModel(value: CGFloat($0.duration / totalDuration), color: $0.color)
        }

        return (chartItems, "Всего за день: \(formattedDuration(totalDuration))")
    }

    func clippedDuration(for record: ActivityRecord, startOfDay: Date, endOfDay: Date) -> TimeInterval {
        let intervalStart = max(record.startedAt, startOfDay)
        let intervalEnd = min(record.endedAt ?? nowProvider(), endOfDay)
        return intervalEnd.timeIntervalSince(intervalStart)
    }

    func categoryTitle(for activityID: UUID) -> String {
        guard
            let activity = activity(id: activityID),
            let categoryName = category(id: activity.categoryLocalID)?.baseName,
            categoryName.isEmpty == false
        else {
            return "Без категории"
        }
        return categoryName
    }

    func activity(id: UUID) -> Activity? {
        activities.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours) ч \(minutes) мин" : "\(hours) ч"
        }
        return "\(max(minutes, 0)) мин"
    }

    func formattedTime(_ date: Date?) -> String {
        guard let date else { return "В процессе" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func recordCountTitle(_ count: Int) -> String {
        if count % 10 == 1 && count % 100 != 11 {
            return "запись"
        }
        if (2...4).contains(count % 10) && (12...14).contains(count % 100) == false {
            return "записи"
        }
        return "записей"
    }

    var shouldShowActiveItems: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: nowProvider())
    }

    func makeHighlightedDates() -> Set<Date> {
        var dates = Set<Date>()
        for record in activityRecords where record.isDeleted == false {
            let startDate = Calendar.current.startOfDay(for: record.startedAt)
            let endDate = Calendar.current.startOfDay(for: record.endedAt ?? nowProvider())
            var cursor = startDate
            while cursor <= endDate {
                dates.insert(cursor)
                guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: cursor) else { break }
                cursor = nextDate
            }
        }
        return dates
    }
}

struct ActivityOverviewViewModel {
    let selectedDate: Date
    let activeItems: [ActivityOverviewActiveItemViewModel]
    let chartSegments: [ActivityOverviewChartSegmentViewModel]
    let chartSummary: String
    let categoryItems: [ActivityOverviewCategoryItemViewModel]
    let recordItems: [ActivityOverviewRecordItemViewModel]

    static let empty = ActivityOverviewViewModel(
        selectedDate: Date(),
        activeItems: [],
        chartSegments: [],
        chartSummary: "",
        categoryItems: [],
        recordItems: []
    )
}

struct ActivityOverviewActiveItemViewModel {
    let id: UUID
    let activity: Activity
    let categoryName: String?
    let startedAt: Date
}

struct ActivityOverviewChartSegmentViewModel {
    let value: CGFloat
    let color: UIColor
}

struct ActivityOverviewCategoryItemViewModel {
    let title: String
    let subtitle: String
    let duration: TimeInterval
    let color: UIColor
}

struct ActivityOverviewRecordItemViewModel {
    let id: UUID
    let title: String
    let subtitle: String
    let duration: String
    let iconName: String
    let iconColor: UIColor
}
