import UIKit
import DesignSystem
import DesignTokens
import Domain
import SnapKit

@MainActor
final class ActivityEditorViewController: BaseViewController, ActivityEditorView {
    private let presenter: ActivityEditorPresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let iconSectionView = UIView()
    private let iconPreviewBackgroundView = UIView()
    private let iconPreviewImageView = ImageResolverImageView(
        resolverSource: .systemSymbol,
        preferredSymbolConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
    )
    private let nameField = CommonTextField(configuration: .init(hint: "Название задачи"))
    private let categoryContainerView = UIView()
    private let categoryHeaderButton = UIButton(type: .system)
    private let categoryTitleLabel = UILabel()
    private let categoryValueLabel = UILabel()
    private let categoryChevronImageView = UIImageView()
    private let quickCategoryScrollView = UIScrollView()
    private let quickCategoryStackView = UIStackView()
    private let variationField = CommonTextField(configuration: .init(hint: "Название вариации"))
    private let addVariationButton = UIButton(type: .system)
    private let variationsTableView = ContentSizedTableView(frame: .zero, style: .plain)
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Сохранить")
        )
    )

    private var variationInput = ""
    private var categoryTitleCenteredConstraint: NSLayoutConstraint?
    private var categoryTitleTopConstraint: NSLayoutConstraint?
    private var categoryValueBottomConstraint: NSLayoutConstraint?
    private var quickCategoryHeightConstraint: NSLayoutConstraint?
    private var quickCategoryBottomConstraint: NSLayoutConstraint?
    private var currentVariations: [String] = []

    init(presenter: ActivityEditorPresenter) {
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

    func render(viewModel: ActivityEditorViewModel) {
        title = viewModel.title
        nameField.text = viewModel.name
        iconPreviewBackgroundView.backgroundColor = viewModel.color.uiColor
        iconPreviewImageView.tintColor = .white
        iconPreviewImageView.setImage(named: viewModel.iconName)
        let hasSelectedCategory = viewModel.selectedCategoryName != nil
        categoryTitleLabel.text = "Категория деятельности"
        categoryTitleLabel.font = hasSelectedCategory
            ? UIFont.systemFont(ofSize: 13, weight: .light)
            : UIFont.systemFont(ofSize: 17, weight: .regular)
        categoryTitleLabel.textColor = DesignColor.textSecondary
        categoryValueLabel.isHidden = !hasSelectedCategory
        categoryValueLabel.text = viewModel.selectedCategoryName
        categoryTitleCenteredConstraint?.isActive = !hasSelectedCategory
        categoryTitleTopConstraint?.isActive = hasSelectedCategory
        categoryValueBottomConstraint?.isActive = hasSelectedCategory
        bottomContainer.primaryButton?.isEnabled = viewModel.isSaveEnabled
        rebuildQuickCategories(
            categories: viewModel.quickCategories,
            selectedCategoryID: viewModel.selectedCategoryID
        )
        currentVariations = viewModel.variations
        rebuildVariations(viewModel.variations)
    }
}

private extension ActivityEditorViewController {
    func setupView() {
        view.backgroundColor = DesignColor.backgroundPrimary

        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(makeIconSection())
        contentStackView.addArrangedSubview(nameField)
        contentStackView.addArrangedSubview(makeCategorySection())
        contentStackView.addArrangedSubview(makeVariationsSection())

        nameField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateName(text)
        }

        variationField.onTextChanged = { [weak self] text in
            self?.variationInput = text
        }

        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapSave()
        }
        view.addSubview(bottomContainer)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomContainer.snp.top)
        }

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

    func makeIconSection() -> UIView {
        iconSectionView.backgroundColor = .clear
        iconPreviewBackgroundView.layer.cornerRadius = 16
        iconPreviewBackgroundView.isUserInteractionEnabled = true
        iconPreviewBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectIcon)))
        iconSectionView.addSubview(iconPreviewBackgroundView)
        iconPreviewBackgroundView.addSubview(iconPreviewImageView)

        iconSectionView.snp.makeConstraints { make in
            make.height.equalTo(56)
        }

        iconPreviewBackgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 56, height: 56))
        }

        iconPreviewImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        return iconSectionView
    }

    func makeCategorySection() -> UIView {
        categoryContainerView.backgroundColor = DesignColor.backgroundSecondary
        categoryContainerView.layer.cornerRadius = 12

        categoryHeaderButton.backgroundColor = .clear
        categoryHeaderButton.addTarget(self, action: #selector(handleSelectCategory), for: .touchUpInside)
        categoryContainerView.addSubview(categoryHeaderButton)

        categoryTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        categoryTitleLabel.textColor = DesignColor.textSecondary
        categoryTitleLabel.text = "Категория деятельности"
        categoryTitleLabel.numberOfLines = 1

        categoryValueLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        categoryValueLabel.textColor = DesignColor.textPrimary
        categoryValueLabel.numberOfLines = 1
        categoryValueLabel.isHidden = true

        categoryChevronImageView.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        )
        categoryChevronImageView.tintColor = DesignColor.textSecondary
        categoryChevronImageView.contentMode = .scaleAspectFit

        quickCategoryScrollView.showsHorizontalScrollIndicator = false

        quickCategoryStackView.axis = .horizontal
        quickCategoryStackView.spacing = DesignSpacing.small
        quickCategoryScrollView.addSubview(quickCategoryStackView)

        categoryHeaderButton.addSubview(categoryTitleLabel)
        categoryHeaderButton.addSubview(categoryValueLabel)
        categoryHeaderButton.addSubview(categoryChevronImageView)
        categoryContainerView.addSubview(quickCategoryScrollView)

        categoryTitleCenteredConstraint = categoryTitleLabel.centerYAnchor.constraint(equalTo: categoryHeaderButton.centerYAnchor)
        categoryTitleTopConstraint = categoryTitleLabel.topAnchor.constraint(equalTo: categoryHeaderButton.topAnchor, constant: 2)
        categoryValueBottomConstraint = categoryValueLabel.bottomAnchor.constraint(equalTo: categoryHeaderButton.bottomAnchor, constant: -2)

        categoryHeaderButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.regular)
            make.height.equalTo(44)
        }

        categoryChevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 7, height: 12))
        }

        categoryTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(categoryChevronImageView.snp.leading).offset(-DesignSpacing.small)
        }

        categoryValueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(categoryChevronImageView.snp.leading).offset(-DesignSpacing.small)
        }

        quickCategoryScrollView.snp.makeConstraints { make in
            make.top.equalTo(categoryHeaderButton.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalTo(categoryHeaderButton)
        }
        quickCategoryHeightConstraint = quickCategoryScrollView.heightAnchor.constraint(equalToConstant: 30)
        quickCategoryHeightConstraint?.isActive = true
        quickCategoryBottomConstraint = quickCategoryScrollView.bottomAnchor.constraint(
            equalTo: categoryContainerView.bottomAnchor,
            constant: -DesignSpacing.medium
        )
        quickCategoryBottomConstraint?.isActive = true

        quickCategoryStackView.snp.makeConstraints { make in
            make.edges.equalTo(quickCategoryScrollView.contentLayoutGuide)
            make.height.equalTo(quickCategoryScrollView.frameLayoutGuide)
        }

        categoryTitleCenteredConstraint?.isActive = true

        return categoryContainerView
    }

    func makeVariationsSection() -> UIView {
        let container = UIView()
        container.backgroundColor = DesignColor.backgroundSecondary
        container.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = "Вариации задачи"
        container.addSubview(titleLabel)

        let addRow = UIStackView()
        addRow.axis = .horizontal
        addRow.alignment = .center
        addRow.spacing = DesignSpacing.small
        container.addSubview(addRow)

        addVariationButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addVariationButton.tintColor = DesignColor.accent
        addVariationButton.addTarget(self, action: #selector(handleAddVariation), for: .touchUpInside)

        addRow.addArrangedSubview(variationField)
        addRow.addArrangedSubview(addVariationButton)

        variationsTableView.backgroundColor = .clear
        variationsTableView.separatorStyle = .none
        variationsTableView.isScrollEnabled = false
        variationsTableView.dragInteractionEnabled = true
        variationsTableView.dataSource = self
        variationsTableView.delegate = self
        variationsTableView.dragDelegate = self
        variationsTableView.dropDelegate = self
        variationsTableView.register(VariationTableCell.self, forCellReuseIdentifier: VariationTableCell.reuseIdentifier)
        container.addSubview(variationsTableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        addRow.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSpacing.small)
            make.leading.trailing.equalToSuperview().inset(DesignSpacing.medium)
        }

        addVariationButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        variationsTableView.snp.makeConstraints { make in
            make.top.equalTo(addRow.snp.bottom).offset(DesignSpacing.medium)
            make.leading.trailing.bottom.equalToSuperview().inset(DesignSpacing.regular)
        }
        variationsTableView.setContentHuggingPriority(.required, for: .vertical)
        variationsTableView.setContentCompressionResistancePriority(.required, for: .vertical)

        return container
    }

    func rebuildQuickCategories(categories: [Domain.Category], selectedCategoryID: UUID?) {
        quickCategoryStackView.arrangedSubviews.forEach {
            quickCategoryStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let hasQuickCategories = categories.isEmpty == false
        quickCategoryScrollView.isHidden = !hasQuickCategories
        quickCategoryHeightConstraint?.constant = hasQuickCategories ? 30 : 0
        quickCategoryBottomConstraint?.constant = hasQuickCategories ? -DesignSpacing.medium : 0

        categories.forEach { category in
            let pill = QuickCategoryPillButton(
                title: category.baseName,
                isSelected: category.localID == selectedCategoryID
            )
            pill.addAction(
                UIAction { [weak self] _ in
                    self?.presenter.didSelectQuickCategory(category.localID)
                },
                for: .touchUpInside
            )
            quickCategoryStackView.addArrangedSubview(pill)
        }
    }

    func rebuildVariations(_ variations: [String]) {
        variationsTableView.reloadData()
        variationsTableView.layoutIfNeeded()
    }

    @objc
    func handleSelectIcon() {
        presenter.didTapSelectIcon()
    }

    @objc
    func handleSelectCategory() {
        presenter.didTapSelectCategory()
    }

    @objc
    func handleAddVariation() {
        presenter.didTapAddVariation(variationInput)
        variationInput = ""
        variationField.text = ""
    }
}

@MainActor
private final class QuickCategoryPillButton: UIButton {
    init(title: String, isSelected: Bool) {
        super.init(frame: .zero)
        layer.cornerRadius = 15
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
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

@MainActor
private final class ContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            guard oldValue != contentSize else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

extension ActivityEditorViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentVariations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VariationTableCell.reuseIdentifier, for: indexPath) as? VariationTableCell else {
            return UITableViewCell()
        }
        cell.apply(title: currentVariations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.presenter.deleteVariation(at: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension ActivityEditorViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: currentVariations[indexPath.row] as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = currentVariations[indexPath.row]
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: currentVariations.count - 1, section: 0)
        presenter.moveVariation(from: sourceIndexPath.row, to: destinationIndexPath.row)
        coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

@MainActor
private final class VariationTableCell: UITableViewCell {
    static let reuseIdentifier = "VariationTableCell"

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let gripImageView = UIImageView(image: UIImage(systemName: "line.3.horizontal"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTypography.bodyRegular16.font
        titleLabel.textColor = DesignColor.textPrimary
        containerView.addSubview(titleLabel)

        gripImageView.translatesAutoresizingMaskIntoConstraints = false
        gripImageView.tintColor = DesignColor.textSecondary
        gripImageView.contentMode = .scaleAspectFit
        containerView.addSubview(gripImageView)

        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        gripImageView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(DesignSpacing.small)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(title: String) {
        titleLabel.text = title
    }
}
