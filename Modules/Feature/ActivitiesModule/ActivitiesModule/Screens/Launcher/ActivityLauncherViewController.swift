import UIKit
import DesignSystem
import DesignTokens
import Domain

@MainActor
final class ActivityLauncherViewController: BaseViewController, ActivityLauncherView {
    private let presenter: ActivityLauncherPresenter
    private var viewModel = ActivityLauncherViewModel(items: [], emptyTitle: "")

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyLabel = UILabel()

    init(presenter: ActivityLauncherPresenter) {
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

    func render(viewModel: ActivityLauncherViewModel) {
        self.viewModel = viewModel
        emptyLabel.isHidden = viewModel.items.isEmpty == false
        tableView.isHidden = viewModel.items.isEmpty
        tableView.reloadData()
    }
}

private extension ActivityLauncherViewController {
    func setupView() {
        title = "Начать задачу"
        view.backgroundColor = DesignColor.backgroundPrimary

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(handleAdd)
        )

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по названиям"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ActivityLauncherCell.self, forCellReuseIdentifier: ActivityLauncherCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = DesignTypography.bodyMedium17.font
        emptyLabel.textColor = DesignColor.textSecondary
        emptyLabel.text = "Нет задач для запуска"
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc
    func handleAdd() {
        presenter.didTapAdd()
    }
}

extension ActivityLauncherViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: ActivityLauncherCell.reuseIdentifier, for: indexPath) as? ActivityLauncherCell
        else {
            return UITableViewCell()
        }

        let item = viewModel.items[indexPath.row]
        cell.apply(viewModel: item)
        cell.onTap = { [weak self, weak tableView] in
            tableView?.deselectRow(at: indexPath, animated: true)
            self?.presenter.didTapStart(at: indexPath.row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectItem(at: indexPath.row)
    }
}

extension ActivityLauncherViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter.didUpdateSearchQuery(searchController.searchBar.text ?? "")
    }
}

@MainActor
private final class ActivityLauncherCell: UITableViewCell {
    static let reuseIdentifier = "ActivityLauncherCell"

    var onTap: (() -> Void)?

    private let contentCard = ActivityRowContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        selectionStyle = .none
        contentView.backgroundColor = .white
        preservesSuperviewLayoutMargins = false
        separatorInset = .zero
        layoutMargins = .zero
        contentView.addSubview(contentCard)
        contentCard.onTap = { [weak self] in
            self?.onTap?()
        }

        NSLayoutConstraint.activate([
            contentCard.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSpacing.regular),
            contentCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSpacing.regular),
            contentCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(viewModel: ActivityLauncherItemViewModel) {
        let activity = Activity(
            localID: viewModel.id,
            remoteID: nil,
            lastModifiedVersion: nil,
            name: viewModel.name,
            categoryLocalID: nil,
            categoryRemoteID: nil,
            iconName: viewModel.iconName,
            color: viewModel.color,
            variations: [],
            isDirty: false,
            isDeleted: false
        )
        contentCard.apply(
            activity: activity,
            categoryName: viewModel.categoryName,
            trailingStyle: viewModel.activeRecord.map { .stop(startedAt: $0.startedAt) } ?? .play,
            rowBackgroundColor: .white
        )
    }
}
