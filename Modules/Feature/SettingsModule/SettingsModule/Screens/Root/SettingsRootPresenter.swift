import Domain
import Foundation

@MainActor
protocol SettingsRootView: AnyObject {
    func render(viewModel: SettingsRootViewModel)
    func setLoading(_ isLoading: Bool)
    func showLogoutConfirmation()
    func showError(message: String)
}

@MainActor
final class SettingsRootPresenter: SettingsRootPresenting {
    weak var view: SettingsRootView?

    private let service: SettingsFeatureServiceProtocol
    private let onOpenProfile: () -> Void
    private let onOpenSecurity: () -> Void
    private let onSessionFinished: @MainActor () -> Void

    private var currentSessionID: Int64?
    private var isLoading = false

    init(
        service: SettingsFeatureServiceProtocol,
        onOpenProfile: @escaping () -> Void,
        onOpenSecurity: @escaping () -> Void,
        onSessionFinished: @escaping @MainActor () -> Void
    ) {
        self.service = service
        self.onOpenProfile = onOpenProfile
        self.onOpenSecurity = onOpenSecurity
        self.onSessionFinished = onSessionFinished
    }

    func viewDidLoad() {
        if let cachedUser = service.cachedUser() {
            view?.render(viewModel: makeViewModel(user: cachedUser))
        } else {
            view?.render(viewModel: .placeholder)
        }

        if let cachedSessions = service.cachedSessions() {
            currentSessionID = cachedSessions.currentSessionID
        }

        reload()
    }

    func viewWillAppear() {
        reload()
    }

    func didTapProfile() {
        onOpenProfile()
    }

    func didTapSecurity() {
        onOpenSecurity()
    }

    func didTapLogout() {
        view?.showLogoutConfirmation()
    }

    func didConfirmLogout() {
        guard isLoading == false else { return }

        Task { [weak self] in
            guard let self else { return }
            setLoading(true)

            do {
                let sessionID = try await resolveCurrentSessionID()
                try await service.logoutCurrentDevice(sessionID: sessionID)
                onSessionFinished()
            } catch {
                setLoading(false)
                view?.showError(message: error.localizedDescription)
            }
        }
    }
}

private extension SettingsRootPresenter {
    func reload() {
        guard isLoading == false else { return }

        let hasCachedUser = service.cachedUser() != nil

        Task { [weak self] in
            guard let self else { return }
            if hasCachedUser == false {
                setLoading(true)
            }

            do {
                let user = try await service.fetchUser()
                let sessions = try await service.fetchSessions()
                currentSessionID = sessions.currentSessionID
                view?.render(viewModel: makeViewModel(user: user))
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
        view?.setLoading(isLoading)
    }

    func resolveCurrentSessionID() async throws -> Int64 {
        if let currentSessionID {
            return currentSessionID
        }

        if let cachedSessions = service.cachedSessions() {
            currentSessionID = cachedSessions.currentSessionID
            return cachedSessions.currentSessionID
        }

        let sessions = try await service.fetchSessions()
        currentSessionID = sessions.currentSessionID
        return sessions.currentSessionID
    }

    func makeViewModel(user: User) -> SettingsRootViewModel {
        SettingsRootViewModel(
            profileName: user.firstName?.settingsDisplayValue ?? "Имя не заполнено",
            profileEmail: user.email?.settingsDisplayValue ?? "Почта не указана"
        )
    }
}

struct SettingsRootViewModel {
    let profileName: String
    let profileEmail: String

    static let placeholder = SettingsRootViewModel(
        profileName: "Загрузка профиля",
        profileEmail: " "
    )
}
