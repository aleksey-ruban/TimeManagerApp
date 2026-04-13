import UIKit
import DesignSystem
import DesignTokens
import Domain

@MainActor
final class CategoryPickerViewController: BaseViewController, CategoryPickerView {
    private let presenter: CategoryPickerPresenter

    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let searchBar = UISearchBar()
    private let newCategoryField = CommonTextField(configuration: .init(hint: "Название новой категории"))
    private let selectedCategoryContainer = UIStackView()
    private let myCategoriesContainer = UIStackView()
    private let myCategoriesPlaceholderLabel = UILabel()
    private let searchResultsController = CategorySearchResultsViewController()
    private let searchResultsContainer = UIView()
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Продолжить", isEnabled: false),
            gradient: .init(isEnabled: false)
        )
    )
    private var scrollBottomConstraint: NSLayoutConstraint?
    private var searchResultsBottomConstraint: NSLayoutConstraint?

    init(presenter: CategoryPickerPresenter) {
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBottomInsets()
    }

    func render(viewModel: CategoryPickerViewModel) {
        newCategoryField.text = viewModel.newCategoryName
        bottomContainer.primaryButton?.isEnabled = viewModel.canContinueWithNewCategory
        rebuildSelectedCategory(viewModel.selectedCategory)
        rebuildMyCategories(viewModel.myCategories, selectedCategoryID: viewModel.selectedCategory?.localID)
    }

    func renderSearchResults(viewModel: CategoryPickerSearchViewModel) {
        let hasQuery = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        searchResultsContainer.isHidden = hasQuery == false ? false : true
        scrollView.isHidden = hasQuery
        searchResultsController.render(
            viewModel: viewModel,
            onSelect: { [weak self] categoryID in
                self?.presenter.didSelectCategory(categoryID)
            }
        )
    }
}

private extension CategoryPickerViewController {
    func setupView() {
        title = "Выбор категории"
        view.backgroundColor = DesignColor.backgroundPrimary

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Готово",
            style: .done,
            target: self,
            action: #selector(handleApplySelectedCategory)
        )

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Поиск по категориям"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        view.addSubview(searchBar)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        searchResultsContainer.translatesAutoresizingMaskIntoConstraints = false
        searchResultsContainer.isHidden = true
        view.addSubview(searchResultsContainer)

        addChild(searchResultsController)
        searchResultsContainer.addSubview(searchResultsController.view)
        searchResultsController.view.translatesAutoresizingMaskIntoConstraints = false
        searchResultsController.didMove(toParent: self)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = DesignSpacing.large
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(newCategoryField)
        contentStackView.addArrangedSubview(selectedCategoryContainer)
        contentStackView.addArrangedSubview(makeSection(title: "Мои категории", contentView: myCategoriesContainer))

        selectedCategoryContainer.axis = .horizontal
        selectedCategoryContainer.alignment = .leading
        selectedCategoryContainer.distribution = .fill
        myCategoriesContainer.axis = .vertical
        myCategoriesContainer.spacing = DesignSpacing.small

        myCategoriesPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        myCategoriesPlaceholderLabel.numberOfLines = 0
        myCategoriesPlaceholderLabel.font = DesignTypography.bodyRegular15.font
        myCategoriesPlaceholderLabel.textColor = DesignColor.textSecondary
        myCategoriesPlaceholderLabel.text = "Создайте свою категорию"

        newCategoryField.onTextChanged = { [weak self] text in
            self?.presenter.didUpdateNewCategoryName(text)
        }

        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapContinue()
        }
        view.addSubview(bottomContainer)

        scrollBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        searchResultsBottomConstraint = searchResultsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DesignSpacing.xSmall),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.medium),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.medium),

            scrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: DesignSpacing.xSmall),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            searchResultsContainer.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: DesignSpacing.xSmall),
            searchResultsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            searchResultsController.view.topAnchor.constraint(equalTo: searchResultsContainer.topAnchor),
            searchResultsController.view.leadingAnchor.constraint(equalTo: searchResultsContainer.leadingAnchor),
            searchResultsController.view.trailingAnchor.constraint(equalTo: searchResultsContainer.trailingAnchor),
            searchResultsController.view.bottomAnchor.constraint(equalTo: searchResultsContainer.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DesignSpacing.large),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: DesignSpacing.large),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -DesignSpacing.large),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -120),

            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scrollBottomConstraint?.isActive = true
        searchResultsBottomConstraint?.isActive = true
    }

    func makeSection(title: String, contentView: UIView) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = title
        container.addSubview(titleLabel)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSpacing.small),
            contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    func rebuildSelectedCategory(_ category: Domain.Category?) {
        selectedCategoryContainer.arrangedSubviews.forEach {
            selectedCategoryContainer.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let category else {
            selectedCategoryContainer.isHidden = true
            return
        }
        selectedCategoryContainer.isHidden = false

        let pill = PillButtonView(title: category.baseName, isSelected: true, showsDelete: true)
        configurePillAppearance(pill, isSelected: true)
        pill.onDelete = { [weak self] in
            self?.presenter.didClearSelectedCategory()
        }
        pill.addAction(
            UIAction { [weak self] _ in
                self?.presenter.didSelectCategory(category.localID)
            },
            for: .touchUpInside
        )
        selectedCategoryContainer.addArrangedSubview(makeLeadingPillRow(with: pill))
    }

    func rebuildMyCategories(_ categories: [Domain.Category], selectedCategoryID: UUID?) {
        myCategoriesContainer.arrangedSubviews.forEach {
            myCategoriesContainer.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard categories.isEmpty == false else {
            myCategoriesContainer.addArrangedSubview(myCategoriesPlaceholderLabel)
            return
        }

        let flow = WrappingPillsView()
        categories.forEach { category in
            let pill = PillButtonView(
                title: category.baseName,
                isSelected: category.localID == selectedCategoryID,
                showsDelete: true
            )
            configurePillAppearance(
                pill,
                isSelected: category.localID == selectedCategoryID
            )
            pill.onDelete = { [weak self] in
                self?.confirmDeleteCategory(category)
            }
            pill.addAction(
                UIAction { [weak self] _ in
                    self?.presenter.didSelectCategory(category.localID)
                },
                for: .touchUpInside
            )
            flow.addPill(pill)
        }
        myCategoriesContainer.addArrangedSubview(flow)
    }

    func configurePillAppearance(_ pill: PillButtonView, isSelected: Bool) {
        pill.applySelection(isSelected)
        pill.layer.borderWidth = 0
    }

    func makeLeadingPillRow(with pill: UIView) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .leading
        row.distribution = .fill

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(pill)
        row.addArrangedSubview(spacer)
        return row
    }

    func confirmDeleteCategory(_ category: Domain.Category) {
        let alert = UIAlertController(
            title: "Удалить категорию?",
            message: "Категория «\(category.baseName)» будет удалена.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
                self?.presenter.didDeleteCategory(category.localID)
            }
        )
        present(alert, animated: true)
    }

    @objc
    func handleApplySelectedCategory() {
        presenter.didTapApplySelectedCategory()
    }

    func updateBottomInsets() {
        let bottomInset = max(bottomContainer.bounds.height + 32, 120)
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        searchResultsController.additionalScrollBottomInset = bottomInset
    }
}

extension CategoryPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let hasQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        searchResultsContainer.isHidden = !hasQuery
        scrollView.isHidden = hasQuery
        presenter.didUpdateSearchQuery(searchText)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let hasQuery = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        searchResultsContainer.isHidden = !hasQuery
        scrollView.isHidden = hasQuery
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        searchResultsContainer.isHidden = true
        scrollView.isHidden = false
        presenter.didUpdateSearchQuery("")
    }
}

@MainActor
private final class CategorySearchResultsViewController: BaseViewController {
    private var viewModel = CategoryPickerSearchViewModel(items: [])
    private var onSelect: ((UUID) -> Void)?
    private let tableView = UITableView(frame: .zero, style: .plain)
    var additionalScrollBottomInset: CGFloat = 0 {
        didSet {
            tableView.contentInset.bottom = additionalScrollBottomInset
            tableView.verticalScrollIndicatorInsets.bottom = additionalScrollBottomInset
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignColor.backgroundPrimary
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategorySearchCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func render(viewModel: CategoryPickerSearchViewModel, onSelect: @escaping (UUID) -> Void) {
        self.viewModel = viewModel
        self.onSelect = onSelect
        tableView.reloadData()
    }
}

extension CategorySearchResultsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategorySearchCell", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = item.title
        configuration.secondaryText = item.isSelected ? "Выбрана" : nil
        cell.contentConfiguration = configuration
        cell.accessoryType = item.isSelected ? .checkmark : .none
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect?(viewModel.items[indexPath.row].id)
    }
}

@MainActor
private final class WrappingPillsView: UIView {
    private let stackView = UIStackView()
    private var pills: [UIView] = []
    private var lastLaidOutWidth: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = DesignSpacing.small
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addPill(_ pill: UIView) {
        pills.append(pill)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let availableWidth = bounds.width
        guard availableWidth > 0, abs(lastLaidOutWidth - availableWidth) > 0.5 || stackView.arrangedSubviews.isEmpty else {
            return
        }

        lastLaidOutWidth = availableWidth
        rebuildRows(for: availableWidth)
    }

    private func rebuildRows(for availableWidth: CGFloat) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        var currentRow = makeRow()
        var currentRowWidth: CGFloat = 0

        for pill in pills {
            let pillWidth = pill.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            let spacing = currentRow.arrangedSubviews.isEmpty ? 0 : DesignSpacing.small
            if currentRow.arrangedSubviews.isEmpty == false,
               currentRowWidth + spacing + pillWidth > availableWidth {
                appendSpacer(to: currentRow)
                stackView.addArrangedSubview(currentRow)
                currentRow = makeRow()
                currentRowWidth = 0
            }

            currentRow.addArrangedSubview(pill)
            currentRowWidth += (currentRow.arrangedSubviews.count > 1 ? DesignSpacing.small : 0) + pillWidth
        }

        if currentRow.arrangedSubviews.isEmpty == false {
            appendSpacer(to: currentRow)
            stackView.addArrangedSubview(currentRow)
        }
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .leading
        row.distribution = .fill
        row.spacing = DesignSpacing.small
        return row
    }

    private func appendSpacer(to row: UIStackView) {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(spacer)
    }
}
