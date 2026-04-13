import UIKit
import DesignSystem
import DesignTokens
import Domain

@MainActor
final class ActivityListViewController: BaseViewController, ActivityListView {
    private let presenter: ActivityListPresenter
    private var viewModel = ActivityListViewModel(items: [], emptyStateTitle: "", emptyStateSubtitle: "")

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateStackView = UIStackView()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()
    private let searchBar = UISearchBar()
    private let bottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(title: "Добавить задачу")
        )
    )
    private let tableBottomInset: CGFloat = 120

    init(presenter: ActivityListPresenter) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableInsets()
    }

    func render(viewModel: ActivityListViewModel) {
        self.viewModel = viewModel
        emptyTitleLabel.text = viewModel.emptyStateTitle
        emptySubtitleLabel.text = viewModel.emptyStateSubtitle
        emptyStateStackView.isHidden = viewModel.items.isEmpty == false
        tableView.isHidden = viewModel.items.isEmpty
        tableView.reloadData()
    }
}

private extension ActivityListViewController {
    func setupView() {
        title = "Мои задачи"
        view.backgroundColor = DesignColor.backgroundPrimary

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleAdd)
        )

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        view.addSubview(searchBar)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ActivityListCell.self, forCellReuseIdentifier: ActivityListCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyStateStackView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateStackView.axis = .vertical
        emptyStateStackView.spacing = DesignSpacing.small
        emptyStateStackView.alignment = .center
        view.addSubview(emptyStateStackView)

        emptyTitleLabel.font = DesignTypography.bodyMedium17.font
        emptyTitleLabel.textColor = DesignColor.textPrimary

        emptySubtitleLabel.font = DesignTypography.bodyRegular15.font
        emptySubtitleLabel.textColor = DesignColor.textSecondary
        emptySubtitleLabel.numberOfLines = 0
        emptySubtitleLabel.textAlignment = .center

        emptyStateStackView.addArrangedSubview(emptyTitleLabel)
        emptyStateStackView.addArrangedSubview(emptySubtitleLabel)

        view.addSubview(bottomContainer)
        bottomContainer.primaryButton?.onTap = { [weak self] in
            self?.presenter.didTapAdd()
        }

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DesignSpacing.xSmall),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.medium),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.medium),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: DesignSpacing.small),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.xLarge),
            emptyStateStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.xLarge),

            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc
    func handleAdd() {
        presenter.didTapAdd()
    }

    func updateTableInsets() {
        let bottomInset = bottomContainer.bounds.height + tableBottomInset
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}

extension ActivityListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityListCell.reuseIdentifier, for: indexPath) as? ActivityListCell else {
            return UITableViewCell()
        }
        
        let item = viewModel.items[indexPath.row]
        cell.apply(viewModel: item)
        cell.onTap = { [weak self, weak tableView] in
            tableView?.deselectRow(at: indexPath, animated: true)
            self?.presenter.didSelectItem(at: indexPath.row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectItem(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.presenter.didDeleteItem(at: indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = DesignColor.destructive

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
}

extension ActivityListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.didUpdateSearchQuery(searchText)
    }
}

@MainActor
private final class ActivityListCell: UITableViewCell {
    static let reuseIdentifier = "ActivityListCell"

    var onTap: (() -> Void)?

    private let activityView = ActivityRowContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
        contentView.backgroundColor = .white
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero
        contentView.addSubview(activityView)
        activityView.onTap = { [weak self] in
            self?.onTap?()
        }

        NSLayoutConstraint.activate([
            activityView.topAnchor.constraint(equalTo: contentView.topAnchor),
            activityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSpacing.regular),
            activityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSpacing.regular),
            activityView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ActivityListItemViewModel) {
        let activity = Activity(
            localID: viewModel.id,
            remoteID: nil,
            lastModifiedVersion: nil,
            name: viewModel.name,
            categoryLocalID: nil,
            categoryRemoteID: nil,
            iconName: viewModel.iconName,
            color: viewModel.color,
            variations: Array(repeating: ActivityVariation(localID: UUID(), remoteID: nil, value: "", position: 0, isDeleted: false), count: viewModel.variationCount),
            isDirty: false,
            isDeleted: false
        )
        activityView.apply(
            activity: activity,
            categoryName: viewModel.categoryName,
            trailingStyle: .play,
            rowBackgroundColor: .white
        )
    }
}
