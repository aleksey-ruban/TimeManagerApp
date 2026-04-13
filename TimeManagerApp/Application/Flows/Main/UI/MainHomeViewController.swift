import UIKit
import CommonSync
import DesignSystem
import DesignTokens
import FeatureActivitiesModule
import FeatureAnalyticsModule

@MainActor
final class MainHomeViewController: UIViewController {
    private let activitySummaryWidget: ActivitySummaryWidgetView
    private let frequentWidget: FrequentlyUsedActivitiesWidgetView
    private let myActivitiesWidget: MyActivitiesWidgetView
    private let analyticsWidget: ChronometryAnalyticsWidgetView

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let observerBag = NotificationObserverBag()

    init(
        activitySummaryWidget: ActivitySummaryWidgetView,
        frequentWidget: FrequentlyUsedActivitiesWidgetView,
        myActivitiesWidget: MyActivitiesWidgetView,
        analyticsWidget: ChronometryAnalyticsWidgetView
    ) {
        self.activitySummaryWidget = activitySummaryWidget
        self.frequentWidget = frequentWidget
        self.myActivitiesWidget = myActivitiesWidget
        self.analyticsWidget = analyticsWidget
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        startObservingActivityUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshWidgets()
    }
}

private extension MainHomeViewController {
    func setupView() {
        navigationItem.title = "Главная"
//        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .automatic
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

//        titleLabel.font = DesignTypography.displaySemibold32.font
//        titleLabel.textColor = DesignColor.textPrimary
//        titleLabel.numberOfLines = 0
//        titleLabel.text = "Управление активностями"
//
//        subtitleLabel.font = DesignTypography.bodyRegular15.font
//        subtitleLabel.textColor = DesignColor.textSecondary
//        subtitleLabel.numberOfLines = 0
//        subtitleLabel.text = "Быстрый доступ к активностям, хронометражам и их аналитике."

        contentStackView.addArrangedSubview(analyticsWidget)
        contentStackView.addArrangedSubview(activitySummaryWidget)
        contentStackView.addArrangedSubview(frequentWidget)
        contentStackView.addArrangedSubview(myActivitiesWidget)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DesignSpacing.regular),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DesignSpacing.regular),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DesignSpacing.regular),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DesignSpacing.xxLarge),
        ])
    }

    func startObservingActivityUpdates() {
        guard observerBag.observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: ActivitiesFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshWidgetsIfVisible()
                }
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshWidgetsIfVisible()
                }
            }
        ]
    }

    func refreshWidgets() {
        analyticsWidget.refresh()
        activitySummaryWidget.refresh()
        frequentWidget.refresh()
    }

    func refreshWidgetsIfVisible() {
        guard isViewLoaded, view.window != nil else { return }
        refreshWidgets()
    }
}
