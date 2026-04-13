import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class ChronometryWeeklyIssueDetailsViewController: BaseViewController, ChronometryWeeklyIssueDetailsView {
    private let presenter: ChronometryWeeklyIssueDetailsPresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let summaryCardView = ChronometryWeeklyIssueSummaryCardView()
    private let daysStackView = UIStackView()
    private let placeholderLabel = UILabel()

    init(presenter: ChronometryWeeklyIssueDetailsPresenter) {
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

    func render(viewModel: ChronometryWeeklyIssueDetailsViewModel) {
        navigationItem.title = viewModel.title
        summaryCardView.apply(viewModel: viewModel)
        placeholderLabel.text = viewModel.placeholderText
        placeholderLabel.isHidden = viewModel.placeholderText == nil

        daysStackView.arrangedSubviews.forEach {
            daysStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        viewModel.dayCards.forEach {
            daysStackView.addArrangedSubview(ChronometryIssueDayCardView(viewModel: $0))
        }
    }

    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            alert.dismiss(animated: true)
        }
    }
}

private extension ChronometryWeeklyIssueDetailsViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        daysStackView.axis = .vertical
        daysStackView.spacing = DesignSpacing.medium

        placeholderLabel.font = DesignTypography.bodyRegular15.font
        placeholderLabel.textColor = DesignColor.textSecondary
        placeholderLabel.numberOfLines = 0

        contentStackView.addArrangedSubview(summaryCardView)
        contentStackView.addArrangedSubview(daysStackView)
        contentStackView.addArrangedSubview(placeholderLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.xxLarge)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }
    }
}

private final class ChronometryWeeklyIssueSummaryCardView: UIView {
    private let subtitleLabel = UILabel()
    private let severityLabel = AnalyticsInsetLabel()
    private let parametersStackView = UIStackView()
    private let recommendationLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryWeeklyIssueDetailsViewModel) {
        subtitleLabel.text = viewModel.subtitle
        severityLabel.text = viewModel.severityText
        severityLabel.backgroundColor = viewModel.severityColor
        severityLabel.isHidden = viewModel.severityText.isEmpty
        recommendationLabel.text = viewModel.recommendation

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

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)

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

        severityLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.trailing.lessThanOrEqualTo(severityLabel.snp.leading).offset(-DesignSpacing.small)
        }

        parametersStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(parametersStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }
    }
}

private final class ChronometryIssueDayCardView: UIView {
    init(viewModel: ChronometryIssueDayCardViewModel) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 20
        DesignShadow.applyWidgetShadow(to: self)

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = viewModel.title
        addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.text = viewModel.subtitle
        addSubview(subtitleLabel)

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        addSubview(stackView)

        viewModel.parameterLines.forEach { line in
            let label = UILabel()
            label.font = DesignTypography.labelRegular13.font
            label.textColor = DesignColor.textSecondary
            label.numberOfLines = 0
            label.text = line
            stackView.addArrangedSubview(label)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
