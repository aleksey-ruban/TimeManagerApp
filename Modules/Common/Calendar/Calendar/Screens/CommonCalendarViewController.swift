import UIKit
import DesignTokens

@MainActor
public final class CommonCalendarViewController: UIViewController {
    private let configuration: CommonCalendarConfiguration
    private let monthProvider: CommonCalendarMonthProviding
    private let onSelectDate: (Date) -> Void
    private let nowProvider: @Sendable () -> Date

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var didScrollToBottom = false

    public convenience init(
        configuration: CommonCalendarConfiguration,
        onSelectDate: @escaping (Date) -> Void
    ) {
        self.init(
            configuration: configuration,
            monthProvider: CommonCalendarMonthProvider(),
            nowProvider: Date.init,
            onSelectDate: onSelectDate
        )
    }

    init(
        configuration: CommonCalendarConfiguration,
        monthProvider: CommonCalendarMonthProviding,
        nowProvider: @escaping @Sendable () -> Date,
        onSelectDate: @escaping (Date) -> Void
    ) {
        self.configuration = CommonCalendarConfiguration(
            selectedDate: configuration.selectedDate,
            highlightedDates: Set(configuration.highlightedDates.map { Calendar.current.startOfDay(for: $0) }),
            allowsFutureDates: configuration.allowsFutureDates
        )
        self.monthProvider = monthProvider
        self.nowProvider = nowProvider
        self.onSelectDate = onSelectDate
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init(
        selectedDate: Date,
        highlightedDates: Set<Date> = [],
        allowsFutureDates: Bool = false,
        onSelectDate: @escaping (Date) -> Void
    ) {
        self.init(
            configuration: CommonCalendarConfiguration(
                selectedDate: selectedDate,
                highlightedDates: highlightedDates,
                allowsFutureDates: allowsFutureDates
            ),
            onSelectDate: onSelectDate
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        buildMonths()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToBottomIfNeeded()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottomIfNeeded(force: true)
    }
}

private extension CommonCalendarViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary
        title = "Календарь"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отменить",
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сегодня",
            style: .plain,
            target: self,
            action: #selector(handleToday)
        )

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 20
        scrollView.addSubview(stackView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
        ])
    }

    func buildMonths() {
        let monthDates = monthProvider.makeMonthDates(
            configuration: configuration,
            now: nowProvider()
        )

        monthDates.forEach { monthDate in
            let monthView = CommonCalendarMonthView(
                monthDate: monthDate,
                configuration: configuration,
                monthProvider: monthProvider,
                nowProvider: nowProvider,
                onSelectDate: { [weak self] date in
                    self?.onSelectDate(date)
                    self?.dismiss(animated: true)
                }
            )
            stackView.addArrangedSubview(monthView)
        }
    }

    func scrollToBottomIfNeeded(force: Bool = false) {
        guard didScrollToBottom == false || force else { return }

        view.layoutIfNeeded()
        let targetOffsetY = max(
            -scrollView.adjustedContentInset.top,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        scrollView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: false)
        didScrollToBottom = true
    }

    @objc
    func handleCancel() {
        dismiss(animated: true)
    }

    @objc
    func handleToday() {
        onSelectDate(nowProvider())
        dismiss(animated: true)
    }
}
