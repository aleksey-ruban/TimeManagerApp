import UIKit
import DesignTokens

@MainActor
final class MainSectionPlaceholderViewController: UIViewController {
    private let titleText: String
    private let subtitleText: String
    private let symbolName: String
    private let accentColor: UIColor

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let heroCardView = UIView()
    private let symbolContainerView = UIView()
    private let symbolImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(
        titleText: String,
        subtitleText: String,
        symbolName: String,
        accentColor: UIColor
    ) {
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.symbolName = symbolName
        self.accentColor = accentColor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}

private extension MainSectionPlaceholderViewController {
    func setupView() {
        navigationItem.title = titleText
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        configureHeroCard()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DesignSpacing.xxLarge),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DesignSpacing.large),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DesignSpacing.large),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DesignSpacing.xxLarge),
        ])
    }

    func configureHeroCard() {
        heroCardView.translatesAutoresizingMaskIntoConstraints = false
        heroCardView.backgroundColor = DesignColor.backgroundSecondary
        heroCardView.layer.cornerRadius = 28
        heroCardView.layer.cornerCurve = .continuous

        symbolContainerView.translatesAutoresizingMaskIntoConstraints = false
        symbolContainerView.backgroundColor = accentColor.withAlphaComponent(0.12)
        symbolContainerView.layer.cornerRadius = 24
        symbolContainerView.layer.cornerCurve = .continuous

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.image = UIImage(systemName: symbolName)
        symbolImageView.tintColor = accentColor
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTypography.displaySemibold32.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = titleText

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = DesignTypography.bodyRegular16.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = subtitleText

        heroCardView.addSubview(symbolContainerView)
        symbolContainerView.addSubview(symbolImageView)
        heroCardView.addSubview(titleLabel)
        heroCardView.addSubview(subtitleLabel)
        contentStackView.addArrangedSubview(heroCardView)

        NSLayoutConstraint.activate([
            heroCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),

            symbolContainerView.topAnchor.constraint(equalTo: heroCardView.topAnchor, constant: DesignSpacing.xLarge),
            symbolContainerView.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: DesignSpacing.xLarge),
            symbolContainerView.widthAnchor.constraint(equalToConstant: 72),
            symbolContainerView.heightAnchor.constraint(equalToConstant: 72),

            symbolImageView.centerXAnchor.constraint(equalTo: symbolContainerView.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: symbolContainerView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: symbolContainerView.bottomAnchor, constant: DesignSpacing.large),
            titleLabel.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: DesignSpacing.xLarge),
            titleLabel.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -DesignSpacing.xLarge),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSpacing.small),
            subtitleLabel.leadingAnchor.constraint(equalTo: heroCardView.leadingAnchor, constant: DesignSpacing.xLarge),
            subtitleLabel.trailingAnchor.constraint(equalTo: heroCardView.trailingAnchor, constant: -DesignSpacing.xLarge),
            subtitleLabel.bottomAnchor.constraint(equalTo: heroCardView.bottomAnchor, constant: -DesignSpacing.xLarge),
        ])
    }
}
