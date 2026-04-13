import UIKit
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
enum ActivityRowTrailingStyle {
    case chevron
    case play
    case stop(startedAt: Date)
    case none
}

@MainActor
final class ActivityRowContentView: UIView {
    private let contentView = ActivityRowBaseView(
        metrics: .large,
        titleFont: .systemFont(ofSize: 16, weight: .regular),
        subtitleFont: .systemFont(ofSize: 12, weight: .light)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onTap: (() -> Void)? {
        get { contentView.onTap }
        set { contentView.onTap = newValue }
    }

    func apply(
        activity: Activity,
        categoryName: String?,
        trailingStyle: ActivityRowTrailingStyle,
        rowBackgroundColor: UIColor = DesignColor.backgroundSecondary
    ) {
        contentView.apply(
            activity: activity,
            categoryName: categoryName,
            trailingStyle: trailingStyle,
            rowBackgroundColor: rowBackgroundColor
        )
    }
}

@MainActor
final class CompactActivityRowContentView: UIView {
    private let contentView = ActivityRowBaseView(
        metrics: .compact,
        titleFont: .systemFont(ofSize: 16, weight: .regular),
        subtitleFont: .systemFont(ofSize: 12, weight: .light)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onTap: (() -> Void)? {
        get { contentView.onTap }
        set { contentView.onTap = newValue }
    }

    func apply(
        activity: Activity,
        categoryName: String?,
        trailingStyle: ActivityRowTrailingStyle,
        rowBackgroundColor: UIColor = DesignColor.backgroundSecondary
    ) {
        contentView.apply(
            activity: activity,
            categoryName: categoryName,
            trailingStyle: trailingStyle,
            rowBackgroundColor: rowBackgroundColor
        )
    }
}

@MainActor
private final class ActivityRowBaseView: UIControl {
    private let metrics: Metrics
    var onTap: (() -> Void)?

    private let iconBackgroundView = UIView()
    private let iconImageView: ImageResolverImageView
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelsStackView = UIStackView()
    private let trailingContainerView = UIView()
    private let trailingLabel = UILabel()
    private let trailingImageView = UIImageView()
    private var trailingImageSize = CGSize(width: 30, height: 30)
    private var timer: Timer?

    init(
        metrics: Metrics,
        titleFont: UIFont,
        subtitleFont: UIFont
    ) {
        self.metrics = metrics
        self.iconImageView = ImageResolverImageView(
            resolverSource: .systemSymbol,
            preferredSymbolConfiguration: UIImage.SymbolConfiguration(
                pointSize: metrics.symbolPointSize,
                weight: .regular
            )
        )
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        snp.makeConstraints { make in
            make.height.equalTo(metrics.rowHeight)
        }
        setupView(titleFont: titleFont, subtitleFont: subtitleFont)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(
        activity: Activity,
        categoryName: String?,
        trailingStyle: ActivityRowTrailingStyle,
        rowBackgroundColor: UIColor
    ) {
        let hasCategory = categoryName?.isEmpty == false
        backgroundColor = rowBackgroundColor
        iconBackgroundView.backgroundColor = activity.color.uiColor.withAlphaComponent(1.0)
        iconImageView.tintColor = UIColor.white
        iconImageView.setImage(named: activity.iconName)
        titleLabel.text = activity.name
        subtitleLabel.text = categoryName
        subtitleLabel.isHidden = !hasCategory
        applyTrailingStyle(trailingStyle)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if bounds.contains(point) {
            return true
        }

        let expandedIconFrame = iconBackgroundView.frame.insetBy(dx: -14, dy: -14)
        return expandedIconFrame.contains(point)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, isHidden == false, alpha > 0.01, self.point(inside: point, with: event) else {
            return nil
        }

        return self
    }
}

private extension ActivityRowBaseView {
    func setupView(titleFont: UIFont, subtitleFont: UIFont) {
        layer.cornerRadius = metrics.cornerRadius
        addAction(UIAction { [weak self] _ in
            self?.onTap?()
        }, for: .touchUpInside)

        iconBackgroundView.layer.cornerRadius = metrics.iconContainerSize / 2
        iconBackgroundView.isUserInteractionEnabled = false
        addSubview(iconBackgroundView)

        iconImageView.isUserInteractionEnabled = false
        iconBackgroundView.addSubview(iconImageView)

        titleLabel.font = titleFont
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isUserInteractionEnabled = false

        subtitleLabel.font = subtitleFont
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.isUserInteractionEnabled = false

        labelsStackView.axis = .vertical
        labelsStackView.alignment = .fill
        labelsStackView.distribution = .fill
        labelsStackView.spacing = metrics.labelsSpacing
        labelsStackView.isUserInteractionEnabled = false
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(subtitleLabel)
        addSubview(labelsStackView)

        addSubview(trailingContainerView)

        trailingLabel.font = .monospacedDigitSystemFont(ofSize: metrics.timeFontSize, weight: .regular)
        trailingLabel.textColor = DesignColor.textSecondary
        trailingLabel.isUserInteractionEnabled = false
        trailingContainerView.addSubview(trailingLabel)

        trailingImageView.tintColor = DesignColor.accent
        trailingImageView.contentMode = .scaleAspectFit
        trailingImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingImageView.setContentHuggingPriority(.required, for: .horizontal)
        trailingContainerView.addSubview(trailingImageView)

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(metrics.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(metrics.symbolBoxSize)
        }

        trailingContainerView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview()
        }

        trailingImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(trailingImageSize)
        }

        trailingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalTo(trailingImageView.snp.leading).offset(-metrics.timeToIconSpacing)
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(metrics.iconToTextSpacing)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(trailingContainerView.snp.leading).offset(-metrics.textToTrailingSpacing)
        }
    }

    func applyTrailingStyle(_ style: ActivityRowTrailingStyle) {
        timer?.invalidate()
        timer = nil

        switch style {
        case .chevron:
            trailingContainerView.isHidden = false
            trailingLabel.isHidden = true
            trailingImageView.isHidden = false
            trailingImageView.image = UIImage(named: "StartTask")
            trailingImageView.tintColor = nil
            updateTrailingImageSize(CGSize(width: 30, height: 30))
        case .play:
            trailingContainerView.isHidden = false
            trailingLabel.isHidden = true
            trailingImageView.isHidden = false
            trailingImageView.image = UIImage(named: "StartTask")
            trailingImageView.tintColor = nil
            updateTrailingImageSize(CGSize(width: 30, height: 30))
        case let .stop(startedAt):
            trailingContainerView.isHidden = false
            trailingLabel.isHidden = false
            trailingImageView.isHidden = false
            trailingImageView.image = UIImage(named: "StopTask")
            trailingImageView.tintColor = nil
            updateTrailingImageSize(CGSize(width: 30, height: 30))
            updateElapsedTimeLabel(startedAt: startedAt)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateElapsedTimeLabel(startedAt: startedAt)
                }
            }
        case .none:
            trailingContainerView.isHidden = true
            trailingLabel.isHidden = true
            trailingImageView.isHidden = true
            trailingLabel.text = nil
            trailingImageView.image = nil
        }
    }

    func updateTrailingImageSize(_ size: CGSize) {
        trailingImageSize = size
        trailingImageView.snp.updateConstraints { make in
            make.size.equalTo(size)
        }
    }

    func updateElapsedTimeLabel(startedAt: Date) {
        let elapsed = max(0, Int(Date().timeIntervalSince(startedAt)))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        trailingLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

private extension ActivityRowBaseView {
    struct Metrics {
        let rowHeight: CGFloat
        let cornerRadius: CGFloat
        let leadingInset: CGFloat
        let trailingInset: CGFloat
        let iconContainerSize: CGFloat
        let symbolBoxSize: CGFloat
        let symbolPointSize: CGFloat
        let iconToTextSpacing: CGFloat
        let textToTrailingSpacing: CGFloat
        let timeToIconSpacing: CGFloat
        let timeFontSize: CGFloat
        let labelsSpacing: CGFloat

        static let large = Metrics(
            rowHeight: 56,
            cornerRadius: 20,
            leadingInset: 8,
            trailingInset: 16,
            iconContainerSize: 40,
            symbolBoxSize: 20,
            symbolPointSize: 18,
            iconToTextSpacing: 16,
            textToTrailingSpacing: 12,
            timeToIconSpacing: 8,
            timeFontSize: 14,
            labelsSpacing: 0
        )

        static let compact = Metrics(
            rowHeight: 47,
            cornerRadius: 18,
            leadingInset: 10,
            trailingInset: 12,
            iconContainerSize: 25,
            symbolBoxSize: 14,
            symbolPointSize: 12,
            iconToTextSpacing: 8,
            textToTrailingSpacing: 8,
            timeToIconSpacing: 6,
            timeFontSize: 12,
            labelsSpacing: 2
        )
    }
}
