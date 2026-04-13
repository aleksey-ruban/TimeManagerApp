import Foundation

struct ChronometryDashboardViewModel {
    let controlCard: ChronometryControlCardViewModel
    let historySectionTitle: String
    let historyCards: [ChronometryHistoryCardViewModel]
    let emptyHistoryText: String

    static let empty = ChronometryDashboardViewModel(
        controlCard: .placeholder,
        historySectionTitle: "Прошлые хронометражи",
        historyCards: [],
        emptyHistoryText: "Завершённых хронометражей пока нет"
    )
}

struct ChronometryControlCardViewModel {
    enum PrimaryAction {
        case start
        case forceStart
        case finish
        case none
    }

    let title: String
    let subtitle: String
    let metaLines: [String]
    let tipText: String?
    let primaryActionTitle: String?
    let primaryAction: PrimaryAction
    let showsMenu: Bool

    static let placeholder = ChronometryControlCardViewModel(
        title: "Хронометраж",
        subtitle: "Загрузка",
        metaLines: [],
        tipText: nil,
        primaryActionTitle: nil,
        primaryAction: .none,
        showsMenu: false
    )
}

struct ChronometryHistoryCardViewModel {
    enum BadgeStyle {
        case accent
        case neutral
        case muted
    }

    let id: UUID
    let periodTitle: String
    let summaryText: String
    let badgeText: String
    let badgeStyle: BadgeStyle
}
