import UIKit
import SnapKit
import DesignTokens

@MainActor
final class AuthEmailSummaryView: UIView {
    init(email: String) {
        super.init(frame: .zero)
        setupView(email: email)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension AuthEmailSummaryView {
    func setupView(email: String) {
        backgroundColor = DesignColor.backgroundSecondary
        layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.labelRegular13.font
        titleLabel.textColor = DesignColor.textSecondary
        titleLabel.text = "Электронная почта"

        let emailLabel = UILabel()
        emailLabel.font = DesignTypography.bodyMedium17.font
        emailLabel.textColor = DesignColor.textPrimary
        emailLabel.numberOfLines = 0
        emailLabel.text = email

        addSubview(titleLabel)
        addSubview(emailLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }
}
