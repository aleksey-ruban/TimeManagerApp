import Foundation
import UIKit

struct ChronometryWeeklyIssueDetailsViewModel {
    let title: String
    let subtitle: String
    let severityText: String
    let severityColor: UIColor
    let parameterLines: [String]
    let recommendation: String
    let dayCards: [ChronometryIssueDayCardViewModel]
    let placeholderText: String?

    static let empty = ChronometryWeeklyIssueDetailsViewModel(
        title: "Рекомендация",
        subtitle: "Загрузка",
        severityText: "",
        severityColor: .clear,
        parameterLines: [],
        recommendation: "",
        dayCards: [],
        placeholderText: "Загрузка"
    )
}

struct ChronometryIssueDayCardViewModel {
    let title: String
    let subtitle: String
    let parameterLines: [String]
}
