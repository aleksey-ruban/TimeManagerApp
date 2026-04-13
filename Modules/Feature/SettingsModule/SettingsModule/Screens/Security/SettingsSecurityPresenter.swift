import CoreAuth
import Domain
import Foundation

@MainActor
protocol SettingsSecurityView: AnyObject {
    func render(viewModel: SettingsSecurityViewModel)
    func showLogoutDeviceConfirmation(deviceName: String)
    func showLogoutOthersConfirmation()
    func showError(message: String)
}

@MainActor
final class SettingsSecurityPresenter: SettingsSecurityPresenting {
    weak var view: SettingsSecurityView?

    private let service: SettingsFeatureServiceProtocol

    private var currentSessions = UserSessions(currentSessionID: 0, sessions: [])
    private var isLoading = false
    private var pendingSessionToLogout: UserSession?

    init(service: SettingsFeatureServiceProtocol) {
        self.service = service
    }

    func viewDidLoad() {
        if let cachedSessions = service.cachedSessions() {
            currentSessions = cachedSessions
        }
        render()
        reload()
    }

    func viewWillAppear() {
        reload()
    }

    func didTapLogoutDevice(at index: Int) {
        let sessions = sortedSessions
        guard sessions.indices.contains(index) else { return }
        let session = sessions[index]
        guard session.sessionID != currentSessions.currentSessionID else { return }

        pendingSessionToLogout = session
        view?.showLogoutDeviceConfirmation(deviceName: session.deviceModel)
    }

    func didTapLogoutOthers() {
        guard hasOtherSessions else { return }
        view?.showLogoutOthersConfirmation()
    }

    func didConfirmLogoutDevice() {
        guard let session = pendingSessionToLogout, isLoading == false else { return }
        pendingSessionToLogout = nil

        Task { [weak self] in
            guard let self else { return }
            setLoading(true)

            do {
                let sessions = try await service.logoutDevice(sessionID: session.sessionID)
                currentSessions = sessions
                render()
            } catch {
                view?.showError(message: error.localizedDescription)
            }

            setLoading(false)
        }
    }

    func didConfirmLogoutOthers() {
        guard isLoading == false else { return }

        Task { [weak self] in
            guard let self else { return }
            setLoading(true)

            do {
                let sessions = try await service.logoutOtherDevices()
                currentSessions = sessions
                render()
            } catch {
                view?.showError(message: error.localizedDescription)
            }

            setLoading(false)
        }
    }
}

private extension SettingsSecurityPresenter {
    func reload() {
        guard isLoading == false else { return }

        let hasCachedSessions = service.cachedSessions() != nil

        Task { [weak self] in
            guard let self else { return }
            if hasCachedSessions == false {
                setLoading(true)
            }

            do {
                currentSessions = try await service.fetchSessions()
                render()
            } catch {
                if hasCachedSessions == false {
                    view?.showError(message: error.localizedDescription)
                }
            }

            if hasCachedSessions == false {
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
            viewModel: SettingsSecurityViewModel(
                descriptionText: "Здесь отображаются все активные сессии авторизации. Текущую сессию можно завершить на главном экране настроек.",
                sessionItems: sortedSessions.map(makeItem(for:)),
                emptyStateText: "Активных сессий не найдено.",
                isLoading: isLoading,
                isLogoutOthersEnabled: isLoading == false && hasOtherSessions
            )
        )
    }

    var sortedSessions: [UserSession] {
        currentSessions.sessions.sorted { $0.lastUsedAt > $1.lastUsedAt }
    }

    var hasOtherSessions: Bool {
        currentSessions.sessions.contains(where: { $0.sessionID != currentSessions.currentSessionID })
    }

    func makeItem(for session: UserSession) -> SettingsSecuritySessionItemViewModel {
        let isCurrent = session.sessionID == currentSessions.currentSessionID
        return SettingsSecuritySessionItemViewModel(
            title: session.deviceModel,
            badgeText: isCurrent ? "Текущее устройство" : nil,
            createdAtText: "Вход: \(Self.dateFormatter.string(from: session.createdAt))",
            lastUsedAtText: "Последняя активность: \(Self.dateFormatter.string(from: session.lastUsedAt))",
            showsLogoutAction: !isCurrent
        )
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct SettingsSecurityViewModel {
    let descriptionText: String
    let sessionItems: [SettingsSecuritySessionItemViewModel]
    let emptyStateText: String
    let isLoading: Bool
    let isLogoutOthersEnabled: Bool
}

struct SettingsSecuritySessionItemViewModel {
    let title: String
    let badgeText: String?
    let createdAtText: String
    let lastUsedAtText: String
    let showsLogoutAction: Bool
}
