import Foundation
import UIKit

struct ChronometryDetailsViewModel {
    let periodTitle: String
    let summaryText: String
    let recommendationBadgeText: String
    let recommendationBadgeStyle: ChronometryHistoryCardViewModel.BadgeStyle
    let recordsCard: ChronometryRecordsCardViewModel
    let weeklyRecommendationsTitle: String
    let weeklyRecommendations: [ChronometryWeeklyRecommendationCardViewModel]
    let weeklyRecommendationsPlaceholder: String?
    let daySummariesTitle: String
    let daySummaries: [ChronometryDaySummaryCardViewModel]
    let daySummariesPlaceholder: String?

    static let empty = ChronometryDetailsViewModel(
        periodTitle: "Хронометраж",
        summaryText: "Загрузка",
        recommendationBadgeText: "…",
        recommendationBadgeStyle: .muted,
        recordsCard: .placeholder,
        weeklyRecommendationsTitle: "Рекомендации недели",
        weeklyRecommendations: [],
        weeklyRecommendationsPlaceholder: "Загрузка",
        daySummariesTitle: "Дни записи",
        daySummaries: [],
        daySummariesPlaceholder: "Загрузка"
    )
}

struct ChronometryRecordsCardViewModel {
    let title: String
    let subtitle: String
    let metaLines: [String]
    let buttonTitle: String

    static let placeholder = ChronometryRecordsCardViewModel(
        title: "Данные записи",
        subtitle: "Подготавливаем хронологию",
        metaLines: [],
        buttonTitle: "Открыть хронологию"
    )
}

struct ChronometryWeeklyRecommendationCardViewModel {
    let code: ChronometryIssueCode
    let title: String
    let severityText: String
    let severityColor: UIColor
    let parameterLines: [String]
    let recommendation: String
    let detailButtonTitle: String?
    let detailBadgeText: String?
}

struct ChronometryDaySummaryCardViewModel {
    let date: Date
    let title: String
    let metaLines: [String]
    let issueButtonTitle: String?
    let issueBadgeText: String?
}
