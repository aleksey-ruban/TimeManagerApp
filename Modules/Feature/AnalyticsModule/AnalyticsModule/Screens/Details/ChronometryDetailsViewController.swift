import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class ChronometryDetailsViewController: BaseViewController, ChronometryDetailsView {
    private let presenter: ChronometryDetailsPresenter
    private var viewModel = ChronometryDetailsViewModel.empty

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let headerCardView = ChronometryDetailHeaderCardView()
    private let recordsCardView = ChronometryRecordsCardButton()
    private let weeklyTitleLabel = UILabel()
    private let weeklyStackView = UIStackView()
    private let weeklyPlaceholderLabel = UILabel()
    private let daysTitleLabel = UILabel()
    private let daysStackView = UIStackView()
    private let daysPlaceholderLabel = UILabel()

    init(presenter: ChronometryDetailsPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.view = self
        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    func render(viewModel: ChronometryDetailsViewModel) {
        self.viewModel = viewModel
        navigationItem.title = "Хронометраж"
        headerCardView.apply(viewModel: viewModel)
        recordsCardView.apply(viewModel: viewModel.recordsCard)
        weeklyTitleLabel.text = viewModel.weeklyRecommendationsTitle
        daysTitleLabel.text = viewModel.daySummariesTitle
        weeklyPlaceholderLabel.text = viewModel.weeklyRecommendationsPlaceholder
        daysPlaceholderLabel.text = viewModel.daySummariesPlaceholder
        weeklyPlaceholderLabel.isHidden = viewModel.weeklyRecommendationsPlaceholder == nil
        daysPlaceholderLabel.isHidden = viewModel.daySummariesPlaceholder == nil
        rebuildWeeklyCards(viewModel.weeklyRecommendations)
        rebuildDayCards(viewModel.daySummaries)
    }

    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            alert.dismiss(animated: true)
        }
    }

    func presentDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Что сделать с хронометражом",
            message: nil,
            preferredStyle: .actionSheet
        )
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        alert.addAction(UIAlertAction(title: "Поделиться", style: .default) { [weak self] _ in
            self?.presenter.didTapShare()
        })
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.presentDeleteApproval()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    func presentShareSheet(text: String) {
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(controller, animated: true)
    }
}

private extension ChronometryDetailsViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(handleMenuTap)
        )

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        weeklyTitleLabel.font = DesignTypography.bodyMedium17.font
        weeklyTitleLabel.textColor = DesignColor.textPrimary

        weeklyStackView.axis = .vertical
        weeklyStackView.spacing = DesignSpacing.medium

        weeklyPlaceholderLabel.font = DesignTypography.bodyRegular15.font
        weeklyPlaceholderLabel.textColor = DesignColor.textSecondary
        weeklyPlaceholderLabel.numberOfLines = 0

        daysTitleLabel.font = DesignTypography.bodyMedium17.font
        daysTitleLabel.textColor = DesignColor.textPrimary

        daysStackView.axis = .vertical
        daysStackView.spacing = DesignSpacing.medium

        daysPlaceholderLabel.font = DesignTypography.bodyRegular15.font
        daysPlaceholderLabel.textColor = DesignColor.textSecondary
        daysPlaceholderLabel.numberOfLines = 0

        contentStackView.addArrangedSubview(headerCardView)
        contentStackView.addArrangedSubview(recordsCardView)
        contentStackView.addArrangedSubview(weeklyTitleLabel)
        contentStackView.addArrangedSubview(weeklyStackView)
        contentStackView.addArrangedSubview(weeklyPlaceholderLabel)
        contentStackView.addArrangedSubview(daysTitleLabel)
        contentStackView.addArrangedSubview(daysStackView)
        contentStackView.addArrangedSubview(daysPlaceholderLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.xxLarge)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }

        recordsCardView.onTap = { [weak self] in
            self?.presenter.didTapRecords()
        }
    }

    func rebuildWeeklyCards(_ cards: [ChronometryWeeklyRecommendationCardViewModel]) {
        weeklyStackView.arrangedSubviews.forEach {
            weeklyStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        cards.forEach { card in
            let view = ChronometryWeeklyRecommendationCardView()
            view.apply(viewModel: card)
            view.onOpenDetails = { [weak self] in
                self?.presenter.didTapWeeklyIssue(card.code)
            }
            weeklyStackView.addArrangedSubview(view)
        }
    }

    func rebuildDayCards(_ cards: [ChronometryDaySummaryCardViewModel]) {
        daysStackView.arrangedSubviews.forEach {
            daysStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        cards.forEach { card in
            let view = ChronometryDaySummaryCardView()
            view.apply(viewModel: card)
            view.onOpenIssues = { [weak self] in
                self?.presenter.didTapDayIssues(for: card.date)
            }
            daysStackView.addArrangedSubview(view)
        }
    }

    func presentDeleteApproval() {
        let alert = UIAlertController(
            title: "Удалить хронометраж",
            message: "Период записи и сохранённая аналитика будут удалены",
            preferredStyle: .actionSheet
        )
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.presenter.confirmDelete()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc
    func handleMenuTap() {
        presenter.didTapMenu()
    }
}

private final class ChronometryDetailHeaderCardView: UIView {
    private let periodLabel = UILabel()
    private let summaryLabel = UILabel()
    private let badgeLabel = AnalyticsInsetLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryDetailsViewModel) {
        periodLabel.text = viewModel.periodTitle
        summaryLabel.text = viewModel.summaryText
        badgeLabel.text = viewModel.recommendationBadgeText

        switch viewModel.recommendationBadgeStyle {
        case .accent:
            badgeLabel.backgroundColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
            badgeLabel.textColor = .white
        case .neutral:
            badgeLabel.backgroundColor = UIColor(red: 0.16, green: 0.63, blue: 0.49, alpha: 0.14)
            badgeLabel.textColor = UIColor(red: 0.12, green: 0.50, blue: 0.39, alpha: 1)
        case .muted:
            badgeLabel.backgroundColor = UIColor(red: 0.56, green: 0.61, blue: 0.67, alpha: 0.14)
            badgeLabel.textColor = UIColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 1)
        }
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 28
        DesignShadow.applyWidgetShadow(to: self)

        periodLabel.font = DesignTypography.bodyMedium17.font
        periodLabel.textColor = DesignColor.textPrimary
        periodLabel.numberOfLines = 0
        addSubview(periodLabel)

        summaryLabel.font = DesignTypography.bodyRegular15.font
        summaryLabel.textColor = DesignColor.textSecondary
        summaryLabel.numberOfLines = 0
        addSubview(summaryLabel)

        badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        addSubview(badgeLabel)

        badgeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        periodLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-DesignSpacing.small)
        }

        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(periodLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.bottom.equalToSuperview().inset(DesignSpacing.large)
        }
    }
}

private final class ChronometryRecordsCardButton: UIControl {
    var onTap: (() -> Void)?

    private let iconWrapView = UIView()
    private let iconImageView = UIImageView(image: UIImage(systemName: "waveform.path.ecg.rectangle"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaStackView = UIStackView()
    private let buttonLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryRecordsCardViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        buttonLabel.text = viewModel.buttonTitle

        metaStackView.arrangedSubviews.forEach {
            metaStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        viewModel.metaLines.forEach { line in
            let label = UILabel()
            label.font = DesignTypography.labelRegular13.font
            label.textColor = DesignColor.textSecondary
            label.numberOfLines = 0
            label.text = line
            label.isUserInteractionEnabled = false
            metaStackView.addArrangedSubview(label)
        }
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 28
        DesignShadow.applyWidgetShadow(to: self)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        iconWrapView.backgroundColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 0.12)
        iconWrapView.layer.cornerRadius = 24
        iconWrapView.isUserInteractionEnabled = false
        addSubview(iconWrapView)

        iconImageView.tintColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isUserInteractionEnabled = false
        iconWrapView.addSubview(iconImageView)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isUserInteractionEnabled = false
        addSubview(subtitleLabel)

        metaStackView.axis = .vertical
        metaStackView.spacing = 4
        metaStackView.isUserInteractionEnabled = false
        addSubview(metaStackView)

        buttonLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        buttonLabel.textColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        buttonLabel.isUserInteractionEnabled = false
        addSubview(buttonLabel)

        chevronImageView.tintColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isUserInteractionEnabled = false
        addSubview(chevronImageView)

        iconWrapView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.large)
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 22, height: 22))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(DesignSpacing.large)
            make.leading.equalTo(iconWrapView.snp.trailing).offset(DesignSpacing.medium)
            make.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalTo(titleLabel)
        }

        metaStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalTo(titleLabel)
        }

        buttonLabel.snp.makeConstraints { make in
            make.top.equalTo(metaStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(DesignSpacing.large)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalTo(buttonLabel)
            make.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

private final class ChronometryWeeklyRecommendationCardView: UIView {
    var onOpenDetails: (() -> Void)?

    private let titleLabel = UILabel()
    private let severityLabel = AnalyticsInsetLabel()
    private let parametersStackView = UIStackView()
    private let recommendationLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let detailBadgeLabel = AnalyticsInsetLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryWeeklyRecommendationCardViewModel) {
        titleLabel.text = viewModel.title
        severityLabel.text = viewModel.severityText
        severityLabel.backgroundColor = viewModel.severityColor
        recommendationLabel.text = viewModel.recommendation
        detailButton.isHidden = viewModel.detailButtonTitle == nil
        detailBadgeLabel.isHidden = viewModel.detailBadgeText == nil
        detailButton.setTitle(viewModel.detailButtonTitle, for: .normal)
        detailBadgeLabel.text = viewModel.detailBadgeText

        parametersStackView.arrangedSubviews.forEach {
            parametersStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        viewModel.parameterLines.forEach { line in
            let label = UILabel()
            label.font = DesignTypography.labelRegular13.font
            label.textColor = DesignColor.textSecondary
            label.numberOfLines = 0
            label.text = line
            parametersStackView.addArrangedSubview(label)
        }
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        severityLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        severityLabel.textColor = .white
        severityLabel.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        severityLabel.layer.cornerRadius = 12
        severityLabel.layer.masksToBounds = true
        addSubview(severityLabel)

        parametersStackView.axis = .vertical
        parametersStackView.spacing = 4
        addSubview(parametersStackView)

        recommendationLabel.font = DesignTypography.bodyRegular15.font
        recommendationLabel.textColor = DesignColor.textPrimary
        recommendationLabel.numberOfLines = 0
        addSubview(recommendationLabel)

        detailButton.configuration = .plain()
        detailButton.contentHorizontalAlignment = .leading
        detailButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        detailButton.tintColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        detailButton.addAction(UIAction { [weak self] _ in
            self?.onOpenDetails?()
        }, for: .touchUpInside)
        addSubview(detailButton)

        detailBadgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        detailBadgeLabel.textColor = .white
        detailBadgeLabel.backgroundColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        detailBadgeLabel.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        detailBadgeLabel.layer.cornerRadius = 12
        detailBadgeLabel.layer.masksToBounds = true
        addSubview(detailBadgeLabel)

        severityLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.trailing.lessThanOrEqualTo(severityLabel.snp.leading).offset(-DesignSpacing.small)
        }

        parametersStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(parametersStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        detailButton.snp.makeConstraints { make in
            make.top.equalTo(recommendationLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        detailBadgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(detailButton.snp.trailing).offset(DesignSpacing.small)
            make.centerY.equalTo(detailButton)
        }
    }
}

private final class ChronometryDaySummaryCardView: UIView {
    var onOpenIssues: (() -> Void)?

    private let titleLabel = UILabel()
    private let metaStackView = UIStackView()
    private let issuesButton = UIButton(type: .system)
    private let badgeLabel = AnalyticsInsetLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryDaySummaryCardViewModel) {
        titleLabel.text = viewModel.title
        issuesButton.isHidden = viewModel.issueButtonTitle == nil
        badgeLabel.isHidden = viewModel.issueBadgeText == nil
        issuesButton.setTitle(viewModel.issueButtonTitle, for: .normal)
        badgeLabel.text = viewModel.issueBadgeText

        metaStackView.arrangedSubviews.forEach {
            metaStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        viewModel.metaLines.forEach { line in
            let label = UILabel()
            label.font = DesignTypography.labelRegular13.font
            label.textColor = DesignColor.textSecondary
            label.numberOfLines = 0
            label.text = line
            metaStackView.addArrangedSubview(label)
        }
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)

        metaStackView.axis = .vertical
        metaStackView.spacing = 4
        addSubview(metaStackView)

        issuesButton.configuration = .plain()
        issuesButton.contentHorizontalAlignment = .leading
        issuesButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        issuesButton.tintColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        issuesButton.addAction(UIAction { [weak self] _ in
            self?.onOpenIssues?()
        }, for: .touchUpInside)
        addSubview(issuesButton)

        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        badgeLabel.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.layer.masksToBounds = true
        addSubview(badgeLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        metaStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        issuesButton.snp.makeConstraints { make in
            make.top.equalTo(metaStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        badgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(issuesButton.snp.trailing).offset(DesignSpacing.small)
            make.centerY.equalTo(issuesButton)
        }
    }
}
