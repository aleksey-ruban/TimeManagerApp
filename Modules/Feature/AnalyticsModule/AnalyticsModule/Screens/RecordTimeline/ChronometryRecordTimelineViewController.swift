import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class ChronometryRecordTimelineViewController: BaseViewController, ChronometryRecordTimelineView {
    private let presenter: ChronometryRecordTimelinePresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let subtitleLabel = UILabel()
    private let sectionsStackView = UIStackView()
    private let placeholderLabel = UILabel()

    init(presenter: ChronometryRecordTimelinePresenter) {
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

    func render(viewModel: ChronometryRecordTimelineViewModel) {
        navigationItem.title = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        placeholderLabel.text = viewModel.placeholderText
        placeholderLabel.isHidden = viewModel.placeholderText == nil

        sectionsStackView.arrangedSubviews.forEach {
            sectionsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        viewModel.sections.forEach { section in
            sectionsStackView.addArrangedSubview(ChronometryRecordTimelineSectionView(viewModel: section))
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

private extension ChronometryRecordTimelineViewController {
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

        sectionsStackView.axis = .vertical
        sectionsStackView.spacing = DesignSpacing.large

        placeholderLabel.font = DesignTypography.bodyRegular15.font
        placeholderLabel.textColor = DesignColor.textSecondary
        placeholderLabel.numberOfLines = 0

        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.addArrangedSubview(sectionsStackView)
        contentStackView.addArrangedSubview(placeholderLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.xxLarge)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }
    }
}

private final class ChronometryRecordTimelineSectionView: UIView {
    init(viewModel: ChronometryRecordTimelineSectionViewModel) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = viewModel.title
        addSubview(titleLabel)

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = DesignSpacing.medium
        addSubview(stackView)

        viewModel.entries.forEach { stackView.addArrangedSubview(ChronometryRecordTimelineEntryCardView(viewModel: $0)) }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ChronometryRecordTimelineEntryCardView: UIView {
    init(viewModel: ChronometryRecordTimelineEntryViewModel) {
        super.init(frame: .zero)

        backgroundColor = .white
        layer.cornerRadius = 20
        DesignShadow.applyWidgetShadow(to: self)

        let iconWrapView = UIView()
        iconWrapView.backgroundColor = viewModel.tintColor.withAlphaComponent(0.14)
        iconWrapView.layer.cornerRadius = 20
        addSubview(iconWrapView)

        let iconView = UIImageView(image: UIImage(systemName: viewModel.iconName))
        iconView.tintColor = viewModel.tintColor
        iconView.contentMode = .scaleAspectFit
        iconWrapView.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.title
        addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.font = DesignTypography.labelRegular13.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = viewModel.subtitle.isEmpty ? "Без дополнительной детализации" : viewModel.subtitle
        addSubview(subtitleLabel)

        let timeLabel = UILabel()
        timeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        timeLabel.textColor = DesignColor.textPrimary
        timeLabel.text = viewModel.timeRange
        addSubview(timeLabel)

        iconWrapView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.medium)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(DesignSpacing.medium)
            make.leading.equalTo(iconWrapView.snp.trailing).offset(DesignSpacing.medium)
            make.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalTo(titleLabel)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
