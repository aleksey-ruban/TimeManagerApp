import UIKit
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
public final class FrequentlyUsedActivitiesWidgetView: UIView {
    public var onDidStartActivity: ((String) -> Void)?
    public var onDidSelectActivity: ((UUID) -> Void)?

    private let service: ActivitiesFeatureServiceProtocol
    private let onOpenAll: () -> Void
    private let onAddNew: () -> Void
    private var categories: [Domain.Category] = []
    private var activities: [Activity] = []
    private var activityRecords: [ActivityRecord] = []

    private let backgroundButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let cardsStackView = UIStackView()
    private let openAllButton = LinkButton(configuration: .init(title: "Все задачи"))

    init(
        service: ActivitiesFeatureServiceProtocol,
        onOpenAll: @escaping () -> Void,
        onAddNew: @escaping () -> Void
    ) {
        self.service = service
        self.onOpenAll = onOpenAll
        self.onAddNew = onAddNew
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

            let frequentActivities = frequentlyUsedActivities(limit: 3)
            rebuildCards(with: frequentActivities)
            updateCallToAction(for: frequentActivities.count)
        }
    }
}

private extension FrequentlyUsedActivitiesWidgetView {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        backgroundButton.backgroundColor = .clear
        backgroundButton.addAction(UIAction { [weak self] _ in
            self?.onOpenAll()
        }, for: .touchUpInside)
        addSubview(backgroundButton)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = "Часто запускаемые задачи"
        addSubview(titleLabel)
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 4
        addSubview(cardsStackView)

        openAllButton.onTap = { [weak self] in
            self?.handleCallToActionTap()
        }
        addSubview(openAllButton)

        backgroundButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.large)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        cardsStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        openAllButton.snp.makeConstraints { make in
            make.top.equalTo(cardsStackView.snp.bottom).offset(DesignSpacing.small)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        bringSubviewToFront(titleLabel)
        bringSubviewToFront(cardsStackView)
        bringSubviewToFront(openAllButton)
    }

    func rebuildCards(with activities: [Activity]) {
        cardsStackView.arrangedSubviews.forEach {
            cardsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        activities.forEach { activity in
            let button = FrequentlyUsedActivityButton(
                activity: activity,
                categoryName: category(id: activity.categoryLocalID)?.baseName,
                activeRecord: activeRecord(for: activity.localID)
            )
            button.onTap = { [weak self] in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let message: String?

                    if let activeRecord = self.activeRecord(for: activity.localID) {
                        let record = try? await self.service.stopActivityRecord(id: activeRecord.localID, endedAt: Date())
                        message = record == nil ? nil : "Остановлена задача «\(activity.name)»"
                    } else {
                        let record = try? await self.service.launchActivity(id: activity.localID, variationID: nil)
                        message = record == nil ? nil : "Запущена задача «\(activity.name)»"
                    }

                    guard let message else { return }
                    self.onDidStartActivity?(message)
                    self.refresh()
                }
            }
            cardsStackView.addArrangedSubview(button)
        }
    }

    func updateCallToAction(for activityCount: Int) {
        switch activityCount {
        case 0:
            openAllButton.isHidden = false
            openAllButton.setTitle("Добавить новую задачу")
        case 3:
            openAllButton.isHidden = false
            openAllButton.setTitle("Все задачи")
        default:
            openAllButton.isHidden = false
            openAllButton.setTitle("Добавить новую задачу")
        }
    }

    func handleCallToActionTap() {
        if frequentlyUsedActivities(limit: 3).isEmpty {
            onAddNew()
            return
        }
        onOpenAll()
    }

    func category(id: UUID?) -> Domain.Category? {
        guard let id else { return nil }
        return categories.first(where: { $0.localID == id && $0.isDeleted == false })
    }

    func frequentlyUsedActivities(limit: Int) -> [Activity] {
        let usageCountByActivityID = Dictionary(
            grouping: activityRecords.filter { $0.isDeleted == false },
            by: \.activityLocalID
        ).mapValues(\.count)

        return activities
            .filter { $0.isDeleted == false }
            .sorted { lhs, rhs in
                let lhsCount = usageCountByActivityID[lhs.localID, default: 0]
                let rhsCount = usageCountByActivityID[rhs.localID, default: 0]
                if lhsCount == rhsCount {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsCount > rhsCount
            }
            .prefix(limit)
            .map(\.self)
    }

    func activeRecord(for activityID: UUID) -> ActivityRecord? {
        activityRecords
            .filter { $0.activityLocalID == activityID && $0.endedAt == nil && $0.isDeleted == false }
            .max(by: { $0.startedAt < $1.startedAt })
    }
}

@MainActor
private final class FrequentlyUsedActivityButton: UIView {
    var onTap: (() -> Void)?

    private let rowView = CompactActivityRowContentView()

    init(activity: Activity, categoryName: String?, activeRecord: ActivityRecord?) {
        super.init(frame: .zero)
        addSubview(rowView)
        rowView.apply(
            activity: activity,
            categoryName: categoryName,
            trailingStyle: activeRecord.map { .stop(startedAt: $0.startedAt) } ?? .play,
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
