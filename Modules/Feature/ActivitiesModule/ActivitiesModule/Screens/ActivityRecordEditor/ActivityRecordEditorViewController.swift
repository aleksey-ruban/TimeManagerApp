import UIKit
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
final class ActivityRecordEditorViewController: BaseViewController, ActivityRecordEditorView {
    private let presenter: ActivityRecordEditorPresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let activityContainerView = UIView()
    private let activityTitleLabel = UILabel()
    private let activityRowView = ActivityRowContentView()
    private let startContainerView = UIView()
    private let startTitleLabel = UILabel()
    private let startDatePicker = UIDatePicker()
    private let endContainerView = UIView()
    private let endHeaderStackView = UIStackView()
    private let endTitleLabel = UILabel()
    private let endSwitch = UISwitch()
    private let endDatePicker = UIDatePicker()
    private let variationContainerView = UIView()
    private let variationTitleLabel = UILabel()
    private let variationScrollView = UIScrollView()
    private let variationStackView = UIStackView()
    private let validationLabel = UILabel()
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Сохранить")
        )
    )

    init(presenter: ActivityRecordEditorPresenter) {
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
        presenter.viewDidLoad()
    }

    func render(viewModel: ActivityRecordEditorViewModel) {
        title = viewModel.title
        activityContainerView.isHidden = viewModel.activity == nil

        if let activity = viewModel.activity {
            activityRowView.apply(
                activity: activity,
                categoryName: viewModel.categoryName,
                trailingStyle: .none,
                rowBackgroundColor: .white
            )
        }

        startDatePicker.date = viewModel.startedAt
        endSwitch.isOn = viewModel.endedAt != nil
        endDatePicker.minimumDate = viewModel.startedAt
        endDatePicker.isHidden = viewModel.endedAt == nil
        if let endedAt = viewModel.endedAt {
            endDatePicker.date = max(viewModel.startedAt, endedAt)
        } else {
            endDatePicker.date = viewModel.startedAt
        }

        validationLabel.text = viewModel.validationMessage
        validationLabel.isHidden = viewModel.validationMessage == nil
        bottomContainer.primaryButton?.isEnabled = viewModel.isSaveEnabled

        rebuildVariationOptions(
            options: viewModel.variationOptions,
            selectedVariationID: viewModel.selectedVariationID
        )
    }
}

private extension ActivityRecordEditorViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(makeActivitySection())
        contentStackView.addArrangedSubview(makeStartSection())
        contentStackView.addArrangedSubview(makeEndSection())
        contentStackView.addArrangedSubview(makeVariationSection())
        contentStackView.addArrangedSubview(validationLabel)

        validationLabel.font = DesignTypography.bodyRegular15.font
        validationLabel.textColor = DesignColor.destructive
        validationLabel.numberOfLines = 0
        validationLabel.isHidden = true

        startDatePicker.addTarget(self, action: #selector(handleStartDateChanged), for: .valueChanged)
        endSwitch.addTarget(self, action: #selector(handleEndSwitchChanged), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(handleEndDateChanged), for: .valueChanged)

        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapSave()
        }
        view.addSubview(bottomContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.large)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(120)
        }

        bottomContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func makeActivitySection() -> UIView {
        activityContainerView.backgroundColor = DesignColor.backgroundSecondary
        activityContainerView.layer.cornerRadius = 12

        activityTitleLabel.font = DesignTypography.bodyMedium17.font
        activityTitleLabel.textColor = DesignColor.textPrimary
        activityTitleLabel.text = "Задача"
        activityContainerView.addSubview(activityTitleLabel)
        activityContainerView.addSubview(activityRowView)

        activityTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        activityRowView.snp.makeConstraints { make in
            make.top.equalTo(activityTitleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        return activityContainerView
    }

    func makeStartSection() -> UIView {
        startContainerView.backgroundColor = DesignColor.backgroundSecondary
        startContainerView.layer.cornerRadius = 12

        startTitleLabel.font = DesignTypography.bodyMedium17.font
        startTitleLabel.textColor = DesignColor.textPrimary
        startTitleLabel.text = "Время начала"
        startContainerView.addSubview(startTitleLabel)

        configureDatePicker(startDatePicker)
        startContainerView.addSubview(startDatePicker)

        startTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        startDatePicker.snp.makeConstraints { make in
            make.top.equalTo(startTitleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        return startContainerView
    }

    func makeEndSection() -> UIView {
        endContainerView.backgroundColor = DesignColor.backgroundSecondary
        endContainerView.layer.cornerRadius = 12

        endHeaderStackView.axis = .horizontal
        endHeaderStackView.alignment = .center
        endHeaderStackView.distribution = .equalSpacing
        endContainerView.addSubview(endHeaderStackView)

        endTitleLabel.font = DesignTypography.bodyMedium17.font
        endTitleLabel.textColor = DesignColor.textPrimary
        endTitleLabel.text = "Время окончания"
        endHeaderStackView.addArrangedSubview(endTitleLabel)
        endHeaderStackView.addArrangedSubview(endSwitch)

        configureDatePicker(endDatePicker)
        endContainerView.addSubview(endDatePicker)

        endHeaderStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        endDatePicker.snp.makeConstraints { make in
            make.top.equalTo(endHeaderStackView.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
        }

        return endContainerView
    }

    func makeVariationSection() -> UIView {
        variationContainerView.backgroundColor = DesignColor.backgroundSecondary
        variationContainerView.layer.cornerRadius = 12

        variationTitleLabel.font = DesignTypography.bodyMedium17.font
        variationTitleLabel.textColor = DesignColor.textPrimary
        variationTitleLabel.text = "Вариация"
        variationContainerView.addSubview(variationTitleLabel)

        variationScrollView.showsHorizontalScrollIndicator = false
        variationContainerView.addSubview(variationScrollView)

        variationStackView.axis = .horizontal
        variationStackView.spacing = DesignSpacing.small
        variationScrollView.addSubview(variationStackView)

        variationTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        variationScrollView.snp.makeConstraints { make in
            make.top.equalTo(variationTitleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
            make.bottom.equalToSuperview().inset(DesignSpacing.medium)
            make.height.equalTo(36)
        }

        variationStackView.snp.makeConstraints { make in
            make.edges.equalTo(variationScrollView.contentLayoutGuide)
            make.height.equalTo(variationScrollView.frameLayoutGuide)
        }

        return variationContainerView
    }

    func configureDatePicker(_ picker: UIDatePicker) {
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ru_RU")
    }

    func rebuildVariationOptions(options: [ActivityRecordVariationOption], selectedVariationID: UUID?) {
        variationStackView.arrangedSubviews.forEach {
            variationStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        options.forEach { option in
            let button = VariationOptionPillButton(
                title: option.title,
                isSelected: option.id == selectedVariationID
            )
            button.addAction(
                UIAction { [weak self] _ in
                    self?.presenter.didSelectVariation(option.id)
                },
                for: .touchUpInside
            )
            variationStackView.addArrangedSubview(button)
        }
    }

    @objc
    func handleStartDateChanged() {
        presenter.didUpdateStartedAt(startDatePicker.date)
    }

    @objc
    func handleEndSwitchChanged() {
        presenter.didToggleEndedAt(endSwitch.isOn)
    }

    @objc
    func handleEndDateChanged() {
        presenter.didUpdateEndedAt(endDatePicker.date)
    }
}

@MainActor
private final class VariationOptionPillButton: UIButton {
    init(title: String, isSelected: Bool) {
        super.init(frame: .zero)
        layer.cornerRadius = 15
        layer.masksToBounds = true
        configuration = .plain()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        setTitle(title, for: .normal)
        setTitleColor(DesignColor.textPrimary, for: .normal)
        backgroundColor = .white
        layer.borderWidth = isSelected ? 1.5 : 0
        layer.borderColor = isSelected ? DesignColor.accent.cgColor : UIColor.clear.cgColor
        snp.makeConstraints { make in
            make.height.equalTo(30)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
