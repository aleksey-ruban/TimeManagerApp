import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
final class ChronometryDashboardViewController: BaseViewController, ChronometryDashboardView {
    private let presenter: ChronometryDashboardPresenter
    private var viewModel = ChronometryDashboardViewModel.empty

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let controlCardView = ChronometryControlCardView()
    private let historyTitleLabel = UILabel()
    private let historyStackView = UIStackView()
    private let emptyHistoryLabel = UILabel()

    init(presenter: ChronometryDashboardPresenter) {
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

    func render(viewModel: ChronometryDashboardViewModel) {
        self.viewModel = viewModel
        historyTitleLabel.text = viewModel.historySectionTitle
        emptyHistoryLabel.text = viewModel.emptyHistoryText
        controlCardView.apply(viewModel: viewModel.controlCard)
        rebuildHistoryCards(viewModel.historyCards)
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
            title: "Удалить хронометраж",
            message: "Этот период и его аналитика будут удалены",
            preferredStyle: .actionSheet
        )
        if let popover = alert.popoverPresentationController {
            popover.sourceView = controlCardView
            popover.sourceRect = controlCardView.bounds
        }
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.presenter.confirmDeleteActiveChronometry()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

private extension ChronometryDashboardViewController {
    func setupView() {
        navigationItem.title = "Аналитика"
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        historyTitleLabel.font = DesignTypography.bodyMedium17.font
        historyTitleLabel.textColor = DesignColor.textPrimary

        historyStackView.axis = .vertical
        historyStackView.spacing = DesignSpacing.medium

        emptyHistoryLabel.font = DesignTypography.bodyRegular15.font
        emptyHistoryLabel.textColor = DesignColor.textSecondary
        emptyHistoryLabel.numberOfLines = 0
        emptyHistoryLabel.textAlignment = .center

        contentStackView.addArrangedSubview(controlCardView)
        contentStackView.addArrangedSubview(historyTitleLabel)
        contentStackView.addArrangedSubview(historyStackView)
        contentStackView.addArrangedSubview(emptyHistoryLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.xxLarge)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.xxLarge)
        }

        controlCardView.onPrimaryAction = { [weak self] action in
            self?.presenter.didTapPrimaryAction(action)
        }
        controlCardView.onMenuAction = { [weak self] in
            self?.presenter.didTapControlMenu()
        }
    }

    func rebuildHistoryCards(_ cards: [ChronometryHistoryCardViewModel]) {
        historyStackView.arrangedSubviews.forEach {
            historyStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        emptyHistoryLabel.isHidden = cards.isEmpty == false

        cards.forEach { card in
            let cardView = ChronometryHistoryCardButton()
            cardView.apply(viewModel: card)
            cardView.onTap = { [weak self] in
                self?.presenter.didTapHistoryCard(id: card.id)
            }
            historyStackView.addArrangedSubview(cardView)
        }
    }
}

private final class ChronometryControlCardView: UIView {
    var onPrimaryAction: ((ChronometryControlCardViewModel.PrimaryAction) -> Void)?
    var onMenuAction: (() -> Void)?

    private var currentAction: ChronometryControlCardViewModel.PrimaryAction = .none

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaStackView = UIStackView()
    private let tipLabel = UILabel()
    private let primaryButton = PrimaryButton(
        configuration: PrimaryButtonConfiguration(title: "Продолжить")
    )
    private let menuButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryControlCardViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        tipLabel.text = viewModel.tipText
        tipLabel.isHidden = viewModel.tipText == nil
        currentAction = viewModel.primaryAction
        menuButton.isHidden = viewModel.showsMenu == false

        metaStackView.arrangedSubviews.forEach {
            metaStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        viewModel.metaLines.forEach { line in
            metaStackView.addArrangedSubview(makeMetaRow(text: line))
        }

        if let title = viewModel.primaryActionTitle {
            primaryButton.isHidden = false
            primaryButton.setTitle(title)
        } else {
            primaryButton.isHidden = true
        }
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 28
        DesignShadow.applyWidgetShadow(to: self)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        addSubview(titleLabel)

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        addSubview(subtitleLabel)

        metaStackView.axis = .vertical
        metaStackView.spacing = 8
        addSubview(metaStackView)

        tipLabel.font = DesignTypography.labelRegular13.font
        tipLabel.textColor = DesignColor.textSecondary
        tipLabel.numberOfLines = 0
        addSubview(tipLabel)

        primaryButton.onTap = { [weak self] in
            guard let self else { return }
            self.onPrimaryAction?(self.currentAction)
        }
        addSubview(primaryButton)

        menuButton.tintColor = DesignColor.iconTint
        menuButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        menuButton.addAction(UIAction { [weak self] _ in
            self?.onMenuAction?()
        }, for: .touchUpInside)
        addSubview(menuButton)

        menuButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.size.equalTo(CGSize(width: 28, height: 28))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.lessThanOrEqualTo(menuButton.snp.leading).offset(-DesignSpacing.small)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        metaStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(metaStackView.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        primaryButton.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(DesignSpacing.large)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.bottom.equalToSuperview().inset(DesignSpacing.large)
        }
    }

    private func makeMetaRow(text: String) -> UIView {
        let container = UIView()

        let dotView = UIView()
        dotView.backgroundColor = UIColor(red: 0.19, green: 0.55, blue: 0.95, alpha: 1)
        dotView.layer.cornerRadius = 4
        dotView.isUserInteractionEnabled = false
        container.addSubview(dotView)

        let label = UILabel()
        label.font = DesignTypography.bodyRegular15.font
        label.textColor = DesignColor.textPrimary
        label.numberOfLines = 0
        label.text = text
        label.isUserInteractionEnabled = false
        container.addSubview(label)

        dotView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(2)
            make.size.equalTo(CGSize(width: 8, height: 8))
            make.bottom.lessThanOrEqualToSuperview()
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(dotView.snp.trailing).offset(12)
            make.top.trailing.bottom.equalToSuperview()
        }

        return container
    }
}

private final class ChronometryHistoryCardButton: UIControl {
    var onTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let badgeLabel = PaddingLabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ChronometryHistoryCardViewModel) {
        titleLabel.text = viewModel.periodTitle
        summaryLabel.text = viewModel.summaryText
        badgeLabel.text = viewModel.badgeText

        switch viewModel.badgeStyle {
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
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)

        summaryLabel.font = DesignTypography.bodyRegular15.font
        summaryLabel.textColor = DesignColor.textSecondary
        summaryLabel.numberOfLines = 0
        summaryLabel.isUserInteractionEnabled = false
        addSubview(summaryLabel)

        badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        badgeLabel.layer.cornerRadius = 14
        badgeLabel.layer.masksToBounds = true
        badgeLabel.isUserInteractionEnabled = false
        addSubview(badgeLabel)

        chevronImageView.tintColor = DesignColor.iconTint
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isUserInteractionEnabled = false
        addSubview(chevronImageView)

        badgeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(DesignSpacing.large)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-DesignSpacing.small)
        }

        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.equalToSuperview().inset(DesignSpacing.large)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-DesignSpacing.small)
            make.bottom.equalToSuperview().inset(DesignSpacing.large)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(DesignSpacing.large)
            make.centerY.equalTo(summaryLabel)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}

private final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
