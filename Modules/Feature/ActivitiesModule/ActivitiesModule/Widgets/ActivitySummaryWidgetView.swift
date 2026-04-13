import UIKit
import CommonSync
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
public final class ActivitySummaryWidgetView: UIView, UIGestureRecognizerDelegate {
    public var onDidStopActivity: ((String) -> Void)?
    public var onOpen: (() -> Void)?

    private let service: ActivitiesFeatureServiceProtocol
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var activityRecords: [ActivityRecord] = []

    private let titleLabel = UILabel()
    private let chartRowStackView = UIStackView()
    private let chartColumnView = UIView()
    private let donutChartView = DonutChartView()
    private let totalTimeLabel = UILabel()
    private let legendStackView = UIStackView()
    private let activeStackView = UIStackView()
    private var refreshTimer: Timer?
    private let observerBag = NotificationObserverBag()

    private let palette: [UIColor] = [
        UIColor(red: 0.23, green: 0.63, blue: 0.95, alpha: 1),
        UIColor(red: 0.95, green: 0.60, blue: 0.26, alpha: 1),
        UIColor(red: 0.40, green: 0.78, blue: 0.47, alpha: 1),
        UIColor(red: 0.76, green: 0.47, blue: 0.90, alpha: 1),
    ]

    init(service: ActivitiesFeatureServiceProtocol) {
        self.service = service
        super.init(frame: .zero)
        setupView()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh() {
        Task { @MainActor [weak self] in
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

            rebuildContent()
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateRefreshLifecycle()
    }
}

private extension ActivitySummaryWidgetView {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOpen))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = "Активность"
        addSubview(titleLabel)

        chartRowStackView.axis = .horizontal
        chartRowStackView.alignment = .top
        chartRowStackView.spacing = DesignSpacing.xLarge
        addSubview(chartRowStackView)

        chartRowStackView.addArrangedSubview(chartColumnView)
        chartRowStackView.addArrangedSubview(legendStackView)

        donutChartView.translatesAutoresizingMaskIntoConstraints = false
        chartColumnView.addSubview(donutChartView)

        totalTimeLabel.font = .systemFont(ofSize: 12, weight: .light)
        totalTimeLabel.textColor = DesignColor.textSecondary
        totalTimeLabel.textAlignment = .center
        totalTimeLabel.numberOfLines = 2
        chartColumnView.addSubview(totalTimeLabel)

        legendStackView.axis = .vertical
        legendStackView.spacing = 6
        legendStackView.distribution = .fillEqually

        activeStackView.axis = .vertical
        activeStackView.spacing = 0
        addSubview(activeStackView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.regular)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        chartRowStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        chartColumnView.snp.makeConstraints { make in
            make.width.equalTo(110)
        }

        donutChartView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 110, height: 110))
        }

        totalTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(donutChartView.snp.bottom).offset(8)
            make.centerX.equalTo(donutChartView.snp.centerX)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        activeStackView.snp.makeConstraints { make in
            make.top.equalTo(chartRowStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        startObservingUpdates()
    }

    func rebuildContent() {
        let summary = makeTodaySummary()
        donutChartView.apply(segments: summary.chartSegments)
        totalTimeLabel.text = summary.totalDuration > 0
            ? formattedDuration(summary.totalDuration)
            : "нет данных"

        legendStackView.arrangedSubviews.forEach {
            legendStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        summary.legendItems.forEach { item in
            legendStackView.addArrangedSubview(
                LegendCardView(
                    title: item.title,
                    value: formattedDuration(item.duration),
                    color: item.color
                )
            )
        }

        activeStackView.arrangedSubviews.forEach {
            activeStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let activeRecords = currentActiveRecords()
        activeStackView.isHidden = activeRecords.isEmpty

        activeRecords.forEach { record in
            guard let activity = activity(id: record.activityLocalID) else { return }
            let row = ActiveActivityRowView(
                activity: activity,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                startedAt: record.startedAt
            )
            row.onTap = { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let stopped = try? await self.service.stopActivityRecord(id: record.localID, endedAt: Date())
                    guard stopped != nil else { return }
                    self.onDidStopActivity?("Остановлена задача «\(activity.name)»")
                    self.refresh()
                }
            }
            activeStackView.addArrangedSubview(row)
        }
    }

    func makeTodaySummary() -> (chartSegments: [DonutChartSegment], legendItems: [LegendItem], totalDuration: TimeInterval) {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return emptySummary()
        }

        var durationsByCategory: [String: TimeInterval] = [:]
        var totalDuration: TimeInterval = 0

        for record in activityRecords where record.isDeleted == false {
            let intervalStart = max(record.startedAt, startOfDay)
            let intervalEnd = min(record.endedAt ?? Date(), endOfDay)
            let duration = intervalEnd.timeIntervalSince(intervalStart)
            guard duration > 0 else { continue }

            let title = categoryTitle(for: record.activityLocalID)
            durationsByCategory[title, default: 0] += duration
            totalDuration += duration
        }

        let sortedCategories = durationsByCategory
            .map { (title: $0.key, duration: $0.value) }
            .sorted {
                if $0.duration == $1.duration {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.duration > $1.duration
            }

        let topThree = Array(sortedCategories.prefix(3))
        let otherDuration = sortedCategories.dropFirst(3).reduce(0) { $0 + $1.duration }

        var items = topThree
        if otherDuration > 0 || items.count < 3 {
            items.append((title: "Другое", duration: otherDuration))
        }

        if items.isEmpty {
            items = [(title: "Другое", duration: 0)]
        }

        let colors = Array(palette.prefix(items.count))
        let legendItems = zip(items, colors).map { item, color in
            LegendItem(title: item.title, duration: item.duration, color: color)
        }

        let chartSegments: [DonutChartSegment]
        if totalDuration > 0, legendItems.isEmpty == false {
            let minimumVisibleShare: CGFloat = 0.03
            let rawShares = legendItems.enumerated().map { index, item -> CGFloat in
                if item.duration > 0 {
                    return item.duration / totalDuration
                }

                // Keep the "other" segment visible in the donut even when it is 0.
                return item.title == "Другое" ? minimumVisibleShare : 0
            }

            let totalShare = rawShares.reduce(0, +)
            chartSegments = zip(legendItems, rawShares).map { item, share in
                DonutChartSegment(
                    value: totalShare > 0 ? share / totalShare : 0,
                    color: item.color
                )
            }
        } else {
            chartSegments = []
        }

        return (chartSegments, legendItems, totalDuration)
    }

    func emptySummary() -> (chartSegments: [DonutChartSegment], legendItems: [LegendItem], totalDuration: TimeInterval) {
        let items = zip(["Другое"], palette).map { title, color in
            LegendItem(title: title, duration: 0, color: color)
        }
        return ([], items, 0)
    }

    func startObservingUpdates() {
        guard observerBag.observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: ActivitiesFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshIfVisible()
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshIfVisible()
            }
        ]
    }

    func updateRefreshLifecycle() {
        refreshTimer?.invalidate()
        refreshTimer = nil

        guard window != nil else { return }
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refreshIfVisible() {
        guard window != nil else { return }
        refresh()
    }

    @objc
    func handleOpen() {
        onOpen?()
    }

    func currentActiveRecords() -> [ActivityRecord] {
        activityRecords
            .filter { $0.endedAt == nil && $0.isDeleted == false }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func activity(id: UUID) -> Activity? {
        activities.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
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

    func formattedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return minutes > 0 ? "\(hours) ч \(minutes) мин" : "\(hours) ч"
        }
        return "\(max(minutes, 0)) мин"
    }
}

public extension ActivitySummaryWidgetView {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return touchedView.isDescendant(of: activeStackView) == false
    }
}

private struct LegendItem {
    let title: String
    let duration: TimeInterval
    let color: UIColor
}

private struct DonutChartSegment {
    let value: CGFloat
    let color: UIColor
}

@MainActor
private final class DonutChartView: UIView {
    private let trackLayer = CAShapeLayer()
    private var segmentLayers: [CAShapeLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(trackLayer)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = DesignColor.backgroundSecondary.cgColor
        trackLayer.lineWidth = 14
        trackLayer.lineCap = .round
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = (min(bounds.width, bounds.height) - 14) / 2
        let path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )
        trackLayer.frame = bounds
        trackLayer.path = path.cgPath
        segmentLayers.forEach {
            $0.frame = bounds
            $0.path = path.cgPath
            $0.lineWidth = 14
        }
    }

    func apply(segments: [DonutChartSegment]) {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()

        var start: CGFloat = 0
        for segment in segments {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = segment.color.cgColor
            layer.lineWidth = 14
            layer.lineCap = .butt
            layer.strokeStart = start
            layer.strokeEnd = start + segment.value
            self.layer.addSublayer(layer)
            segmentLayers.append(layer)
            start += segment.value
        }

        setNeedsLayout()
    }
}

@MainActor
private final class LegendCardView: UIView {
    init(title: String, value: String, color: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let dotView = UIView()
        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 3.5
        addSubview(dotView)

        let labelsStackView = UIStackView()
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = 0
        addSubview(labelsStackView)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = title
        labelsStackView.addArrangedSubview(titleLabel)

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 10, weight: .light)
        valueLabel.textColor = DesignColor.textSecondary
        valueLabel.text = value
        labelsStackView.addArrangedSubview(valueLabel)

        snp.makeConstraints { make in
            make.height.equalTo(30)
        }

        dotView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 7, height: 7))
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(dotView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class ActiveActivityRowView: UIView {
    var onTap: (() -> Void)?

    private let rowView = CompactActivityRowContentView()

    init(activity: Activity, categoryName: String?, startedAt: Date) {
        super.init(frame: .zero)
        addSubview(rowView)
        rowView.apply(
            activity: activity,
            categoryName: categoryName,
            trailingStyle: .stop(startedAt: startedAt),
            rowBackgroundColor: .white
        )
        rowView.onTap = { [weak self] in
            self?.onTap?()
        }

        rowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
