import Domain
import Foundation

@MainActor
protocol SettingsProfileEditView: AnyObject {
    func render(viewModel: SettingsProfileEditViewModel)
    func showDeleteAccountConfirmation()
    func showError(message: String)
    func close()
}

@MainActor
final class SettingsProfileEditPresenter: SettingsProfileEditPresenting {
    weak var view: SettingsProfileEditView?

    private let service: SettingsFeatureServiceProtocol
    private let onSessionFinished: @MainActor () -> Void

    private var currentUser: User?
    private var draftName = ""
    private var isLoading = false

    init(
        service: SettingsFeatureServiceProtocol,
        onSessionFinished: @escaping @MainActor () -> Void
    ) {
        self.service = service
        self.onSessionFinished = onSessionFinished
    }

    func viewDidLoad() {
        if let cachedUser = service.cachedUser() {
            currentUser = cachedUser
            draftName = cachedUser.firstName ?? ""
        }
        render()
        loadProfile()
    }

    func didUpdateName(_ name: String) {
        draftName = name
        render()
    }

    func didTapSave() {
        guard canSave else { return }

        Task { [weak self] in
            guard let self else { return }
            setLoading(true)

            do {
                let user = try await service.updateProfile(name: draftName.settingsTrimmedValue)
                currentUser = user
                draftName = user.firstName ?? ""
                setLoading(false)
                view?.close()
            } catch {
                setLoading(false)
                view?.showError(message: error.localizedDescription)
            }
        }
    }

    func didTapDeleteAccount() {
        view?.showDeleteAccountConfirmation()
    }

    func didConfirmDeleteAccount() {
        guard isLoading == false else { return }

        Task { [weak self] in
            guard let self else { return }
            setLoading(true)

            do {
                try await service.deleteAccount()
                onSessionFinished()
            } catch {
                setLoading(false)
                view?.showError(message: error.localizedDescription)
            }
        }
    }
}

private extension SettingsProfileEditPresenter {
    func loadProfile() {
        guard isLoading == false else { return }

        let hasCachedUser = service.cachedUser() != nil

        Task { [weak self] in
            guard let self else { return }
            if hasCachedUser == false {
                setLoading(true)
            }

            do {
                let user = try await service.fetchUser()
                currentUser = user
                draftName = user.firstName ?? ""
                render()
            } catch {
                if hasCachedUser == false {
                    view?.showError(message: error.localizedDescription)
                }
            }

            if hasCachedUser == false {
                setLoading(false)
            }
        }
    }

    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        render()
    }

    func render() {
        view?.render(
            viewModel: SettingsProfileEditViewModel(
                currentName: currentUser?.firstName?.settingsDisplayValue ?? "Имя не заполнено",
                currentEmail: currentUser?.email?.settingsDisplayValue ?? "Почта не указана",
                editableName: draftName,
                email: currentUser?.email ?? "",
                isLoading: isLoading,
                isSaveEnabled: canSave
            )
        )
    }

    var canSave: Bool {
        let initialValue = currentUser?.firstName?.settingsTrimmedValue ?? ""
        let currentValue = draftName.settingsTrimmedValue
        return currentValue.isEmpty == false && currentValue != initialValue && isLoading == false
    }
}

struct SettingsProfileEditViewModel {
    let currentName: String
    let currentEmail: String
    let editableName: String
    let email: String
    let isLoading: Bool
    let isSaveEnabled: Bool
}
