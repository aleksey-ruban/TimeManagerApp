import UIKit
import DesignSystem
import DesignTokens
import Domain

@MainActor
final class ActivityRecordPickerViewController: BaseViewController, ActivityRecordPickerView {
    private let presenter: ActivityRecordPickerPresenter
    private var viewModel = ActivityRecordPickerViewModel(items: [], emptyTitle: "")

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyLabel = UILabel()

    init(presenter: ActivityRecordPickerPresenter) {
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

    func render(viewModel: ActivityRecordPickerViewModel) {
        self.viewModel = viewModel
        emptyLabel.text = viewModel.emptyTitle
        emptyLabel.isHidden = viewModel.items.isEmpty == false
        tableView.isHidden = viewModel.items.isEmpty
        tableView.reloadData()
    }
}

private extension ActivityRecordPickerViewController {
    func setupView() {
        title = "Выбор задачи"
        view.backgroundColor = DesignColor.backgroundPrimary

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
        tableView.register(ActivityRecordPickerCell.self, forCellReuseIdentifier: ActivityRecordPickerCell.reuseIdentifier)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = DesignTypography.bodyMedium17.font
        emptyLabel.textColor = DesignColor.textSecondary
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
}

extension ActivityRecordPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ActivityRecordPickerCell.reuseIdentifier,
                for: indexPath
            ) as? ActivityRecordPickerCell
        else {
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
}

extension ActivityRecordPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter.didUpdateSearchQuery(searchController.searchBar.text ?? "")
    }
}

@MainActor
private final class ActivityRecordPickerCell: UITableViewCell {
    static let reuseIdentifier = "ActivityRecordPickerCell"

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

    func apply(viewModel: ActivityRecordPickerItemViewModel) {
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
        activityView.apply(
            activity: activity,
            categoryName: viewModel.categoryName,
            trailingStyle: .play,
            rowBackgroundColor: .white
        )
    }
}
