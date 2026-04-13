import Foundation

extension String {
    var settingsTrimmedValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var settingsDisplayValue: String? {
        let value = settingsTrimmedValue
        return value.isEmpty ? nil : value
    }
}
