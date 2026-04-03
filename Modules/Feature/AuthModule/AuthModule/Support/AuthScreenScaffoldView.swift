import UIKit
import SnapKit
import DesignSystem
import DesignTokens

@MainActor
final class AuthScreenScaffoldView: UIView {
    let bodyStackView = UIStackView()
    let actionsStackView = UIStackView()
    let primaryButton: PrimaryButton

    private let loadingOverlayView = UIView()
    private let loadingIndicatorContainerView = UIView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    init(
        title: String,
        subtitle: String?,
        primaryButtonTitle: String
    ) {
        self.primaryButton = PrimaryButton(
            configuration: PrimaryButtonConfiguration(
                title: primaryButtonTitle,
                isEnabled: false
            )
        )
        super.init(frame: .zero)
        setupView(title: title, subtitle: subtitle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPrimaryButtonTitle(_ title: String) {
        primaryButton.setTitle(title)
    }

    func setLoading(_ isLoading: Bool) {
        loadingOverlayView.isHidden = !isLoading

        if isLoading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
}

private extension AuthScreenScaffoldView {
    func setupView(title: String, subtitle: String?) {
        backgroundColor = DesignColor.backgroundPrimary

        titleLabel.text = title
        titleLabel.font = DesignTypography.displaySemibold32.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.numberOfLines = 0

        if let subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.font = DesignTypography.bodyRegular15.font
            subtitleLabel.textColor = DesignColor.textPrimary
            subtitleLabel.numberOfLines = 0
        }
        
        contentStackView.axis = .vertical
        bodyStackView.axis = .vertical
        bodyStackView.spacing = 20
        actionsStackView.axis = .vertical
        actionsStackView.spacing = 16
        loadingOverlayView.isHidden = true
        loadingOverlayView.backgroundColor = DesignColor.backgroundPrimary.withAlphaComponent(0.28)
        loadingIndicatorContainerView.backgroundColor = DesignColor.buttonSecondary
        loadingIndicatorContainerView.layer.cornerRadius = DesignSize.loadingIndicatorContainerCornerRadius
        activityIndicatorView.color = DesignColor.textPrimary

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
        addSubview(loadingOverlayView)
        loadingOverlayView.addSubview(loadingIndicatorContainerView)
        loadingIndicatorContainerView.addSubview(activityIndicatorView)

        contentStackView.addArrangedSubview(titleLabel)
        
        if subtitle != nil {
            contentStackView.addArrangedSubview(subtitleLabel)
        }
        
        contentStackView.addArrangedSubview(bodyStackView)
        contentStackView.addArrangedSubview(actionsStackView)
        actionsStackView.addArrangedSubview(primaryButton)

        
        contentStackView.setCustomSpacing(12, after: titleLabel)
        
        if subtitle != nil {
            contentStackView.setCustomSpacing(40, after: subtitleLabel)
        }
        
        contentStackView.setCustomSpacing(40, after: bodyStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 32, left: 55, bottom: 32, right: 55)
            )
        }

        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingIndicatorContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(DesignSize.loadingIndicatorContainerSize)
        }

        activityIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
