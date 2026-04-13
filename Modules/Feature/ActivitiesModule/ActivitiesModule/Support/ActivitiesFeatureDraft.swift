import Domain
import Foundation

struct ActivityDraft: Sendable {
    struct VariationDraft: Sendable {
        let localID: UUID
        let remoteID: Int64?
        let value: String
        let position: Int
        let isDeleted: Bool
    }

    var name: String
    var iconName: String
    var color: ActivityColor
    var categoryID: UUID?
    var variations: [VariationDraft]

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

extension String {
    var normalizedSearchText: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
