import Foundation
import UIKit

struct ChronometryRecordTimelineViewModel {
    let title: String
    let subtitle: String
    let sections: [ChronometryRecordTimelineSectionViewModel]
    let placeholderText: String?

    static let empty = ChronometryRecordTimelineViewModel(
        title: "Хронология записи",
        subtitle: "Загрузка",
        sections: [],
        placeholderText: "Загрузка"
    )
}

struct ChronometryRecordTimelineSectionViewModel {
    let title: String
    let entries: [ChronometryRecordTimelineEntryViewModel]
}

struct ChronometryRecordTimelineEntryViewModel {
    let title: String
    let subtitle: String
    let timeRange: String
    let iconName: String
    let tintColor: UIColor
}
