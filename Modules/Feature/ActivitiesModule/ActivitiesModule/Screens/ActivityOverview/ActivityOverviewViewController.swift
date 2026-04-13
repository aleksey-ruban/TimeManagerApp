import UIKit
import CommonCalendar
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
final class ActivityOverviewViewController: BaseViewController, ActivityOverviewView {
    private let presenter: ActivityOverviewPresenter
    private let calendarAssembly: CommonCalendarAssemblyProtocol
    private var viewModel = ActivityOverviewViewModel.empty

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let dateNavigatorView: UIView & CommonDateNavigatorViewProtocol
    private let activeSectionView = UIStackView()
    private let activeSectionLabel = UILabel()
    private let activeStackView = UIStackView()
    private let chartSectionView = UIStackView()
    private let chartSectionLabel = UILabel()
    private let donutChartView = ActivityDetailsDonutChartView()
    private let chartSummaryLabel = UILabel()
    private let categorySectionView = UIStackView()
    private let categorySectionLabel = UILabel()
    private let categoriesTableView = ContentSizedTableView(frame: .zero, style: .plain)
    private let recordsSectionView = UIStackView()
    private let recordsSectionLabel = UILabel()
    private let recordsTableView = ContentSizedTableView(frame: .zero, style: .plain)
    private let emptyRecordsLabel = UILabel()

    init(
        presenter: ActivityOverviewPresenter,
        dateNavigatorView: UIView & CommonDateNavigatorViewProtocol,
        calendarAssembly: CommonCalendarAssemblyProtocol
    ) {
        self.presenter = presenter
        self.dateNavigatorView = dateNavigatorView
        self.calendarAssembly = calendarAssembly
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        presenter.viewDidDisappear()
    }

    func render(viewModel: ActivityOverviewViewModel) {
        self.viewModel = viewModel
        dateNavigatorView.apply(date: viewModel.selectedDate)

        activeSectionView.isHidden = viewModel.activeItems.isEmpty
        rebuildActiveItems(viewModel.activeItems)

        donutChartView.apply(segments: viewModel.chartSegments)
        chartSummaryLabel.text = viewModel.chartSummary

        categorySectionView.isHidden = viewModel.categoryItems.isEmpty
        categoriesTableView.reloadData()
        categoriesTableView.layoutIfNeeded()

        recordsTableView.reloadData()
        recordsTableView.layoutIfNeeded()
        emptyRecordsLabel.isHidden = viewModel.recordItems.isEmpty == false
    }

    func presentCalendar(selectedDate: Date, highlightedDates: Set<Date>, onSelectDate: @escaping (Date) -> Void) {
        let viewController = calendarAssembly.makeCalendarViewController(
            configuration: CommonCalendarConfiguration(
                selectedDate: selectedDate,
                highlightedDates: highlightedDates,
                allowsFutureDates: false
            ),
            onSelectDate: { @MainActor @Sendable date in
                onSelectDate(date)
            }
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [UISheetPresentationController.Detent.large()]
            sheet.prefersGrabberVisible = false
        }
        present(navigationController, animated: true)
    }
}

private extension ActivityOverviewViewController {
    func setupView() {
        title = "Активность"
        view.backgroundColor = DesignColor.backgroundPrimary

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleAddRecord)
        )

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        setupSectionLabel(activeSectionLabel, text: "Активные задачи")
        setupSectionLabel(chartSectionLabel, text: "Разбиение по категориям")
        setupSectionLabel(categorySectionLabel, text: "Категории за день")
        setupSectionLabel(recordsSectionLabel, text: "Записи активностей")

        setupSectionStackView(activeSectionView)
        setupSectionStackView(chartSectionView)
        setupSectionStackView(categorySectionView)
        setupSectionStackView(recordsSectionView)

        activeStackView.axis = .vertical
        activeStackView.spacing = DesignSpacing.small

        chartSummaryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        chartSummaryLabel.textColor = DesignColor.textSecondary
        chartSummaryLabel.textAlignment = .center
        chartSummaryLabel.numberOfLines = 2

        setupTableView(categoriesTableView)
        categoriesTableView.register(CategoryBreakdownCell.self, forCellReuseIdentifier: CategoryBreakdownCell.reuseIdentifier)

        setupTableView(recordsTableView)
        recordsTableView.register(ActivityRecordTableCell.self, forCellReuseIdentifier: ActivityRecordTableCell.reuseIdentifier)

        emptyRecordsLabel.font = DesignTypography.bodyRegular15.font
        emptyRecordsLabel.textColor = DesignColor.textSecondary
        emptyRecordsLabel.text = "За выбранный день записей нет"
        emptyRecordsLabel.textAlignment = .center
        emptyRecordsLabel.numberOfLines = 0
        emptyRecordsLabel.isHidden = true

        dateNavigatorView.onPreviousDate = { [weak self] in
            self?.presenter.didTapPreviousDate()
        }
        dateNavigatorView.onNextDate = { [weak self] in
            self?.presenter.didTapNextDate()
        }
        dateNavigatorView.onTapDate = { [weak self] in
            self?.presenter.didTapDate()
        }

        contentStackView.addArrangedSubview(dateNavigatorView)
        activeSectionView.addArrangedSubview(activeSectionLabel)
        activeSectionView.addArrangedSubview(activeStackView)
        contentStackView.addArrangedSubview(activeSectionView)

        chartSectionView.addArrangedSubview(chartSectionLabel)
        chartSectionView.addArrangedSubview(donutChartView)
        chartSectionView.addArrangedSubview(chartSummaryLabel)
        contentStackView.addArrangedSubview(chartSectionView)

        categorySectionView.addArrangedSubview(categorySectionLabel)
        categorySectionView.addArrangedSubview(categoriesTableView)
        contentStackView.addArrangedSubview(categorySectionView)

        recordsSectionView.addArrangedSubview(recordsSectionLabel)
        recordsSectionView.addArrangedSubview(recordsTableView)
        recordsSectionView.addArrangedSubview(emptyRecordsLabel)
        contentStackView.addArrangedSubview(recordsSectionView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.large)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }

        donutChartView.snp.makeConstraints { make in
            make.height.equalTo(260)
        }
    }

    func setupSectionLabel(_ label: UILabel, text: String) {
        label.font = DesignTypography.bodyMedium17.font
        label.textColor = DesignColor.textPrimary
        label.text = text
    }

    func setupSectionStackView(_ stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.spacing = DesignSpacing.small
    }

    func setupTableView(_ tableView: UITableView) {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.preservesSuperviewLayoutMargins = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
    }

    func rebuildActiveItems(_ items: [ActivityOverviewActiveItemViewModel]) {
        activeStackView.arrangedSubviews.forEach {
            activeStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        items.forEach { item in
            let rowView = CompactActivityRowContentView()
            rowView.apply(
                activity: item.activity,
                categoryName: item.categoryName,
                trailingStyle: .stop(startedAt: item.startedAt),
                rowBackgroundColor: .white
            )
            rowView.onTap = { [weak self] in
                self?.presenter.didTapActiveItem(id: item.id)
            }
            activeStackView.addArrangedSubview(rowView)
        }
    }

    @objc
    func handleAddRecord() {
        presenter.didTapAddRecord()
    }
}

extension ActivityOverviewViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === categoriesTableView {
            return viewModel.categoryItems.count
        }
        return viewModel.recordItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === categoriesTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryBreakdownCell.reuseIdentifier, for: indexPath) as? CategoryBreakdownCell else {
                return UITableViewCell()
            }
            cell.apply(viewModel: viewModel.categoryItems[indexPath.row])
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityRecordTableCell.reuseIdentifier, for: indexPath) as? ActivityRecordTableCell else {
            return UITableViewCell()
        }
        cell.apply(viewModel: viewModel.recordItems[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView === recordsTableView else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectRecord(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard tableView === recordsTableView else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.presenter.didDeleteRecord(at: indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = DesignColor.destructive

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
}

private struct ActivityDetailsDonutSegment {
    let value: CGFloat
    let color: UIColor
}

@MainActor
private final class ActivityDetailsDonutChartView: UIView {
    private var segmentLayers: [CAShapeLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineWidth: CGFloat = 18
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        segmentLayers.forEach {
            $0.frame = bounds
            $0.path = path.cgPath
            $0.lineWidth = lineWidth
        }
    }

    func apply(segments: [ActivityOverviewChartSegmentViewModel]) {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()

        var start: CGFloat = 0
        for segment in segments where segment.value > 0 {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = segment.color.cgColor
            layer.lineWidth = 18
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
private final class CategoryBreakdownCell: UITableViewCell {
    static let reuseIdentifier = "CategoryBreakdownCell"

    private let dotView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero

        dotView.layer.cornerRadius = 4
        contentView.addSubview(dotView)

        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = DesignColor.textPrimary
        contentView.addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        subtitleLabel.textColor = DesignColor.textSecondary
        contentView.addSubview(subtitleLabel)

        dotView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 8, height: 8))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(dotView.snp.trailing).offset(10)
            make.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ActivityOverviewCategoryItemViewModel) {
        dotView.backgroundColor = viewModel.color
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
    }
}

@MainActor
private final class ActivityRecordTableCell: UITableViewCell {
    static let reuseIdentifier = "ActivityRecordTableCell"

    private let iconBackgroundView = UIView()
    private let iconImageView = ImageResolverImageView(
        resolverSource: .systemSymbol,
        preferredSymbolConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    )
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let durationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero

        iconBackgroundView.layer.cornerRadius = 16
        contentView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)

        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = DesignColor.textPrimary
        contentView.addSubview(titleLabel)

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .light)
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 2
        contentView.addSubview(subtitleLabel)

        durationLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = DesignColor.textPrimary
        durationLabel.textAlignment = .right
        contentView.addSubview(durationLabel)

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7)
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ActivityOverviewRecordItemViewModel) {
        iconBackgroundView.backgroundColor = viewModel.iconColor
        iconImageView.tintColor = .white
        iconImageView.setImage(named: viewModel.iconName)
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        durationLabel.text = viewModel.duration
    }
}

@MainActor
private final class ContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
