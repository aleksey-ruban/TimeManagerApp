import UIKit
import DesignTokens
import DesignSystem
import SnapKit

@MainActor
final class ActivityIconPickerViewController: BaseViewController, ActivityIconPickerView {
    private let presenter: ActivityIconPickerPresenter
    private var viewModel: ActivityIconPickerViewModel?

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let previewContainer = UIView()
    private let previewIconView = ImageResolverImageView(
        resolverSource: .systemSymbol,
        preferredSymbolConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
    )
    private let colorsSectionView = UIView()
    private let iconsSectionView = UIView()
    private lazy var colorsCollectionView = ContentSizedCollectionView(frame: .zero, collectionViewLayout: makeGridLayout())
    private lazy var iconsCollectionView = ContentSizedCollectionView(frame: .zero, collectionViewLayout: makeGridLayout())

    init(presenter: ActivityIconPickerPresenter) {
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

    func render(viewModel: ActivityIconPickerViewModel) {
        self.viewModel = viewModel
        previewContainer.backgroundColor = .white
        previewIconView.tintColor = .white
        previewIconBackgroundView.backgroundColor = viewModel.selectedColor.uiColor
        previewIconView.setImage(named: viewModel.selectedIconName)
        colorsCollectionView.reloadData()
        iconsCollectionView.reloadData()
        colorsCollectionView.collectionViewLayout.invalidateLayout()
        iconsCollectionView.collectionViewLayout.invalidateLayout()
        colorsCollectionView.layoutIfNeeded()
        iconsCollectionView.layoutIfNeeded()
    }
}

private extension ActivityIconPickerViewController {
    var previewIconBackgroundView: UIView {
        previewIconView.superview ?? UIView()
    }

    func setupView() {
        title = "Значок"
        view.backgroundColor = DesignColor.backgroundSecondary
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Готово",
            style: .done,
            target: self,
            action: #selector(handleApply)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(handleClose)
        )

        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        previewContainer.layer.cornerRadius = 12
        contentStackView.addArrangedSubview(previewContainer)
        let previewBadgeView = UIView()
        previewBadgeView.layer.cornerRadius = 16
        previewContainer.addSubview(previewBadgeView)
        previewBadgeView.addSubview(previewIconView)

        colorsSectionView.backgroundColor = .white
        colorsSectionView.layer.cornerRadius = 12
        contentStackView.addArrangedSubview(colorsSectionView)

        iconsSectionView.backgroundColor = .white
        iconsSectionView.layer.cornerRadius = 12
        contentStackView.addArrangedSubview(iconsSectionView)

        colorsCollectionView.backgroundColor = .clear
        colorsCollectionView.setContentHuggingPriority(.required, for: .vertical)
        colorsCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)
        colorsCollectionView.isScrollEnabled = false
        colorsCollectionView.dataSource = self
        colorsCollectionView.delegate = self
        colorsCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        colorsSectionView.addSubview(colorsCollectionView)

        iconsCollectionView.backgroundColor = .clear
        iconsCollectionView.setContentHuggingPriority(.required, for: .vertical)
        iconsCollectionView.setContentCompressionResistancePriority(.required, for: .vertical)
        iconsCollectionView.isScrollEnabled = false
        iconsCollectionView.dataSource = self
        iconsCollectionView.delegate = self
        iconsCollectionView.register(IconGridCell.self, forCellWithReuseIdentifier: IconGridCell.reuseIdentifier)
        iconsSectionView.addSubview(iconsCollectionView)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(DesignSpacing.large)
            make.leading.equalTo(scrollView.frameLayoutGuide).offset(DesignSpacing.large)
            make.trailing.equalTo(scrollView.frameLayoutGuide).inset(DesignSpacing.large)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(DesignSpacing.large)
        }

        previewContainer.snp.makeConstraints { make in
            make.height.equalTo(96)
        }

        previewBadgeView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 56, height: 56))
        }

        previewIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        colorsCollectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(DesignSpacing.small)
            make.bottom.equalToSuperview().inset(DesignSpacing.small)
        }

        iconsCollectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(DesignSpacing.small)
            make.bottom.equalToSuperview().inset(DesignSpacing.small)
        }
    }

    func makeGridLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = DesignSpacing.small
        layout.minimumInteritemSpacing = DesignSpacing.small
        return layout
    }

    @objc
    func handleApply() {
        presenter.didTapApply()
    }

    @objc
    func handleClose() {
        dismiss(animated: true)
    }
}

@MainActor
private final class ContentSizedCollectionView: UICollectionView {
    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        collectionViewLayout.invalidateLayout()
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

extension ActivityIconPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let viewModel else { return 0 }
        return collectionView === colorsCollectionView ? viewModel.availableColors.count : viewModel.availableIcons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel else { return UICollectionViewCell() }

        if collectionView === colorsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.reuseIdentifier, for: indexPath) as! ColorCell
            let color = viewModel.availableColors[indexPath.item]
            cell.apply(color: color.uiColor, isSelected: color == viewModel.selectedColor)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconGridCell.reuseIdentifier, for: indexPath) as! IconGridCell
        let iconName = viewModel.availableIcons[indexPath.item]
        cell.apply(
            iconName: iconName,
            tintColor: viewModel.selectedColor.uiColor,
            isSelected: iconName == viewModel.selectedIconName
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel else { return }
        if collectionView === colorsCollectionView {
            presenter.didSelectColor(viewModel.availableColors[indexPath.item])
        } else {
            presenter.didSelectIcon(viewModel.availableIcons[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 6
        let totalSpacing = DesignSpacing.small * (columns - 1)
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        return CGSize(width: width, height: width)
    }
}

@MainActor
private final class ColorCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCell"

    private let selectionRingView = UIView()
    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectionRingView)
        selectionRingView.addSubview(colorView)
        selectionRingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 48))
        }
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }
        selectionRingView.layer.cornerRadius = 24
        colorView.layer.cornerRadius = 18
        selectionRingView.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        selectionRingView.layer.borderWidth = isSelected ? 3 : 0
        selectionRingView.layer.borderColor = UIColor(hex: 0xD9D9D9).cgColor
    }
}

@MainActor
private final class IconGridCell: UICollectionViewCell {
    static let reuseIdentifier = "IconGridCell"

    private let iconView = ImageResolverImageView(
        resolverSource: .systemSymbol,
        preferredSymbolConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(iconName: String, tintColor: UIColor, isSelected: Bool) {
        iconView.tintColor = DesignColor.iconTint
        iconView.setImage(named: iconName)
        alpha = isSelected ? 1.0 : 0.72
    }
}
