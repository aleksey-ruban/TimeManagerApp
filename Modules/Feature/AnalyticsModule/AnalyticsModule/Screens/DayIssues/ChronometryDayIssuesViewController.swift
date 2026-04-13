import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class ChronometryDayIssuesViewController: BaseViewController, ChronometryDayIssuesView {
    private let presenter: ChronometryDayIssuesPresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let subtitleLabel = UILabel()
    private let cardsStackView = UIStackView()
    private let placeholderLabel = UILabel()

    init(presenter: ChronometryDayIssuesPresenter) {
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

    func render(viewModel: ChronometryDayIssuesViewModel) {
        navigationItem.title = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        placeholderLabel.text = viewModel.placeholderText
        placeholderLabel.isHidden = viewModel.placeholderText == nil

        cardsStackView.arrangedSubviews.forEach {
            cardsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        viewModel.issueCards.forEach {
            cardsStackView.addArrangedSubview(ChronometryDayIssueCardView(viewModel: $0))
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

private extension ChronometryDayIssuesViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0

        cardsStackView.axis = .vertical
        cardsStackView.spacing = DesignSpacing.medium

        placeholderLabel.font = DesignTypography.bodyRegular15.font
        placeholderLabel.textColor = DesignColor.textSecondary
        placeholderLabel.numberOfLines = 0

        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.addArrangedSubview(cardsStackView)
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

private final class ChronometryDayIssueCardView: UIView {
    init(viewModel: ChronometryDayIssueCardViewModel) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.title
        addSubview(titleLabel)

        let severityLabel = AnalyticsInsetLabel()
        severityLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        severityLabel.textColor = .white
        severityLabel.backgroundColor = viewModel.severityColor
        severityLabel.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        severityLabel.layer.cornerRadius = 12
        severityLabel.layer.masksToBounds = true
        severityLabel.text = viewModel.severityText
        addSubview(severityLabel)

        let parameterStackView = UIStackView()
        parameterStackView.axis = .vertical
        parameterStackView.spacing = 4
        addSubview(parameterStackView)

        viewModel.parameterLines.forEach { line in
            let label = UILabel()
            label.font = DesignTypography.labelRegular13.font
            label.textColor = DesignColor.textSecondary
            label.numberOfLines = 0
            label.text = line
            parameterStackView.addArrangedSubview(label)
        }

        let recommendationLabel = UILabel()
        recommendationLabel.font = DesignTypography.bodyRegular15.font
        recommendationLabel.textColor = DesignColor.textPrimary
        recommendationLabel.numberOfLines = 0
        recommendationLabel.text = viewModel.recommendation
        addSubview(recommendationLabel)

        severityLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.trailing.lessThanOrEqualTo(severityLabel.snp.leading).offset(-DesignSpacing.small)
        }

        parameterStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(parameterStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
