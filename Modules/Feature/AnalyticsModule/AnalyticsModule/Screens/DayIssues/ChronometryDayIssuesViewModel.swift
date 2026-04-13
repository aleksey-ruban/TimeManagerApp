import Foundation
import UIKit

struct ChronometryDayIssuesViewModel {
    let title: String
    let subtitle: String
    let issueCards: [ChronometryDayIssueCardViewModel]
    let placeholderText: String?

    static let empty = ChronometryDayIssuesViewModel(
        title: "Проблемы дня",
        subtitle: "Загрузка",
        issueCards: [],
        placeholderText: "Загрузка"
    )
}

struct ChronometryDayIssueCardViewModel {
    let title: String
    let severityText: String
    let severityColor: UIColor
    let parameterLines: [String]
    let recommendation: String
}
