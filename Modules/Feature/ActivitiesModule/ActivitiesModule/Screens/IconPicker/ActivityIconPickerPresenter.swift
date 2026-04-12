import Domain

@MainActor
protocol ActivityIconPickerView: AnyObject {
    func render(viewModel: ActivityIconPickerViewModel)
}

@MainActor
final class ActivityIconPickerPresenter {
    weak var view: ActivityIconPickerView?

    private let iconCatalogService: ActivityIconCatalogServiceProtocol
    private let onApply: (String, ActivityColor) -> Void

    private var selectedIconName: String
    private var selectedColor: ActivityColor

    init(
        iconCatalogService: ActivityIconCatalogServiceProtocol,
        selectedIconName: String,
        selectedColor: ActivityColor,
        onApply: @escaping (String, ActivityColor) -> Void
    ) {
        self.iconCatalogService = iconCatalogService
        self.selectedIconName = selectedIconName
        self.selectedColor = selectedColor
        self.onApply = onApply
    }

    func viewDidLoad() {
        reload()
    }

    func didSelectColor(_ color: ActivityColor) {
        selectedColor = color
        reload()
    }

    func didSelectIcon(_ iconName: String) {
        selectedIconName = iconName
        reload()
    }

    func didTapApply() {
        onApply(selectedIconName, selectedColor)
    }
}

private extension ActivityIconPickerPresenter {
    func reload() {
        view?.render(
            viewModel: ActivityIconPickerViewModel(
                selectedIconName: selectedIconName,
                selectedColor: selectedColor,
                availableColors: ActivityColor.allCases,
                availableIcons: iconCatalogService.availableIcons()
            )
        )
    }
}

struct ActivityIconPickerViewModel {
    let selectedIconName: String
    let selectedColor: ActivityColor
    let availableColors: [ActivityColor]
    let availableIcons: [String]
}
