import CommonSync
import DesignSystem
import DesignTokens
import SnapKit
import UIKit

@MainActor
public final class ChronometryAnalyticsWidgetView: UIView {
    private let service: AnalyticsFeatureServiceProtocol
    private let onOpen: () -> Void

    private let observerBag = NotificationObserverBag()
    private let tapButton = UIButton(type: .system)
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelsStackView = UIStackView()

    init(
        service: AnalyticsFeatureServiceProtocol,
        onOpen: @escaping () -> Void
    ) {
        self.service = service
        self.onOpen = onOpen
        super.init(frame: .zero)
        setupView()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let snapshot = try await service.loadSnapshotAsync()
                applyIcon(for: snapshot.controlState)
                titleLabel.text = Self.title(for: snapshot.controlState)
                subtitleLabel.text = Self.subtitle(for: snapshot.controlState)
            } catch {
                applyIcon(for: nil)
                titleLabel.text = "Хронометражи"
                subtitleLabel.text = "Откройте модуль управления периодами записи"
            }
        }
    }
}

private extension ChronometryAnalyticsWidgetView {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 24
        DesignShadow.applyWidgetShadow(to: self)

        snp.makeConstraints { make in
            make.height.equalTo(96)
        }

        tapButton.addAction(UIAction { [weak self] _ in
            self?.onOpen()
        }, for: .touchUpInside)
        addSubview(tapButton)

        iconView.isUserInteractionEnabled = false
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = 5
        labelsStackView.isUserInteractionEnabled = false
        addSubview(labelsStackView)

        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.isUserInteractionEnabled = false
        labelsStackView.addArrangedSubview(titleLabel)

        subtitleLabel.font = DesignTypography.bodyRegular15.font
        subtitleLabel.textColor = DesignColor.textSecondary
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isUserInteractionEnabled = false
        labelsStackView.addArrangedSubview(subtitleLabel)

        tapButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.lessThanOrEqualTo(CGSize(width: 40, height: 40))
        }

        labelsStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        bringSubviewToFront(tapButton)

        startObserving()
    }

    func startObserving() {
        guard observerBag.observers.isEmpty else { return }
        let notificationCenter = NotificationCenter.default
        observerBag.observers = [
            notificationCenter.addObserver(
                forName: AnalyticsFeatureUpdateCenter.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refresh()
                }
            },
            notificationCenter.addObserver(
                forName: .appSyncServiceDidFinishRun,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refresh()
                }
            }
        ]
    }

    func applyIcon(for state: ChronometryControlState?) {
        let imageName: String

        switch state {
        case .readyToStart, .inProgress:
            imageName = "ChronometryActive"
        case .readyToFinish, .cooldown:
            imageName = "ChronometryInactive"
        case nil:
            imageName = "ChronometryInactive"
        }

        iconView.image = UIImage(named: imageName)
        iconView.tintColor = nil
    }
    
    static func title(for state: ChronometryControlState) -> String {
        switch state {
        case .readyToStart:
            return "Хронометраж"
        case .inProgress:
            return "Хронометраж запущен"
        case .readyToFinish:
            return "Хронометраж записан"
        case .cooldown:
            return "Хронометраж"
        }
    }

    static func subtitle(for state: ChronometryControlState) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        switch state {
        case .readyToStart:
            return "Пора запланировать трекинг"
        case let .inProgress(activeState):
            return activeState.isScheduled
                ? "Запланировано: завтра первый день записи"
                : "Осталось \(7 - activeState.recordedDays) дней"
        case .readyToFinish:
            return "Завершите хронометраж и получите рекомендации"
        case let .cooldown(cooldownState):
            return "Новый запуск лучше после \(formatter.string(from: cooldownState.recommendedStartDate))"
        }
    }
}
