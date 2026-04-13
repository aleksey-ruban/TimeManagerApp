import DesignTokens
import Foundation
import UIKit

enum ChronometryAnalyticsFormatting {
    static func title(for code: ChronometryIssueCode) -> String {
        switch code {
        case .lowFocus:
            return "Фокус быстро проседает"
        case .noBreaks:
            return "В течение дня мало пауз"
        case .tooManyTaskSwitches:
            return "Слишком много переключений"
        case .excessiveMultitasking:
            return "Слишком много параллельных дел"
        case .fragmentedWorkday:
            return "День получается слишком дробным"
        case .longWorkday:
            return "Рабочий день затягивается"
        case .noDaysOff:
            return "Неделе не хватает выходных"
        case .insufficientSleep:
            return "Сна оказалось недостаточно"
        case .irregularSleep:
            return "Режим сна сбивается"
        }
    }

    static func severityText(for severity: ChronometryIssueSeverity) -> String {
        switch severity {
        case .low:
            return "Мягкий сигнал"
        case .medium:
            return "Стоит обратить внимание"
        case .high:
            return "Лучше заняться в первую очередь"
        }
    }

    static func severityColor(for severity: ChronometryIssueSeverity) -> UIColor {
        switch severity {
        case .low:
            return UIColor(red: 0.33, green: 0.66, blue: 0.35, alpha: 1)
        case .medium:
            return UIColor(red: 0.91, green: 0.57, blue: 0.16, alpha: 1)
        case .high:
            return DesignColor.destructive
        }
    }

    static func historyBadgeStyle(for status: ChronometryAnalyticsStatus) -> ChronometryHistoryCardViewModel.BadgeStyle {
        switch status {
        case let .ready(report):
            return report.recommendationCount > 0 ? .accent : .neutral
        case .awaitingSync, .pendingRemoteFetch:
            return .muted
        }
    }

    static func historySummaryText(for status: ChronometryAnalyticsStatus) -> String {
        switch status {
        case let .ready(report):
            if report.recommendationCount > 0 {
                return recommendationsCountText(report.recommendationCount)
            }
            return "Доступна аналитика по записи"
        case .awaitingSync:
            return "Аналитика появится после синхронизации"
        case .pendingRemoteFetch:
            return "Аналитика подгружается"
        }
    }

    static func historyBadgeText(for status: ChronometryAnalyticsStatus) -> String {
        switch status {
        case let .ready(report):
            return report.recommendationCount > 0 ? "\(report.recommendationCount)" : "Данные"
        case .awaitingSync, .pendingRemoteFetch:
            return "…"
        }
    }

    static func recommendationsCountText(_ count: Int) -> String {
        switch count % 100 {
        case 11...14:
            return "\(count) рекомендаций"
        default:
            switch count % 10 {
            case 1:
                return "\(count) рекомендация"
            case 2...4:
                return "\(count) рекомендации"
            default:
                return "\(count) рекомендаций"
            }
        }
    }

    static func issuesCountText(_ count: Int) -> String {
        switch count % 100 {
        case 11...14:
            return "\(count) проблем"
        default:
            switch count % 10 {
            case 1:
                return "\(count) проблема"
            case 2...4:
                return "\(count) проблемы"
            default:
                return "\(count) проблем"
            }
        }
    }

    static func periodText(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let startComponents = calendar.dateComponents([.day, .month, .year], from: startDate)
        let endComponents = calendar.dateComponents([.day, .month, .year], from: endDate)

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "ru_RU")
        monthFormatter.dateFormat = "LLLL"

        if startComponents.year == endComponents.year, startComponents.month == endComponents.month {
            let month = monthFormatter.string(from: startDate)
            return "\(startComponents.day ?? 0)–\(endComponents.day ?? 0) \(month) \(startComponents.year ?? 0)"
        }

        if startComponents.year == endComponents.year {
            return "\(dayMonthText(startDate)) – \(dayMonthText(endDate)) \(startComponents.year ?? 0)"
        }

        return "\(fullDateText(startDate)) – \(fullDateText(endDate))"
    }

    static func fullDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    static func dayMonthText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    static func dayTitleText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: date).capitalized
    }

    static func timeOfDayText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func timeRangeText(startedAt: Date, endedAt: Date?) -> String {
        let start = timeOfDayText(startedAt)
        guard let endedAt else {
            return "\(start) — сейчас"
        }
        return "\(start) — \(timeOfDayText(endedAt))"
    }

    static func parameterText(for parameter: ChronometryIssueParameter) -> String {
        "\(label(for: parameter.key)): \(valueText(for: parameter.value, key: parameter.key))"
    }

    static func label(for key: String) -> String {
        switch key {
        case "FOCUS_SCORE":
            return "Уровень фокуса"
        case "FOCUS_LOSS_MINUTES":
            return "Времени ушло мимо дела"
        case "TOTAL_BREAKS_MINUTES":
            return "Времени на паузы"
        case "BREAKS_MINUTES_PER_HOUR":
            return "Паузы в среднем за час"
        case "TASK_SWITCHES_COUNT":
            return "Переключений между делами"
        case "TASK_SWITCHES_PER_HOUR":
            return "Переключений за час"
        case "AVG_TIME_PER_TASK":
            return "Среднее время на одно дело"
        case "MULTITASK_OVERLAP_MINUTES":
            return "Времени в параллельных делах"
        case "MULTITASK_OVERLAP_MINUTES_PER_HOUR":
            return "Параллельных дел за час"
        case "WORK_SESSION_COUNT":
            return "Количество рабочих отрезков"
        case "AVR_SESSION_DURATION", "AVG_SESSION_DURATION":
            return "Средняя длина рабочего отрезка"
        case "AVG_SESSION_GAP":
            return "Средний перерыв между отрезками"
        case "OVERTIME_MINUTES":
            return "Переработка"
        case "TOTAL_WORK_DAYS":
            return "Рабочих дней"
        case "TOTAL_DAYS_OFF_COUNT":
            return "Выходных дней"
        case "SLEEP_DURATION":
            return "Сон"
        case "SLEEP_DEFICIT_MINUTES":
            return "Недостаток сна"
        case "AVG_SLEEP_DURATION":
            return "Средняя длина сна"
        case "AVG_SLEEP_START_TIME":
            return "Обычно отход ко сну"
        case "SLEEP_START_STD_DEV":
            return "Разброс времени отхода ко сну"
        case "AVG_SLEEP_DURATION_TIME":
            return "Средняя длина сна"
        case "SLEEP_DURATION_STD_DEV":
            return "Разброс длины сна"
        case "WEEKLY_OCCURRENCES":
            return "Сколько раз повторялось за неделю"
        case "MAX_CONSECUTIVE_DAYS":
            return "Максимум дней подряд"
        default:
            return key
                .lowercased()
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    static func dayMetrics(for day: ChronometryAnalyticsDaySummary) -> [String] {
        var lines = [
            "Работа \(formatMinutes(day.workTime))",
            "Личное \(formatMinutes(day.leisureTime))",
            "Отдых \(formatMinutes(day.restTime))"
        ]

        lines.append(day.isWorkDay ? "Отмечен как рабочий день" : "Отмечен как день отдыха")
        lines.append("Длина дня \(formatMinutes(day.workDayDuration))")

        if let focusScore = day.focusScore {
            lines.append("Фокус \(valueText(for: .double(focusScore), key: "FOCUS_SCORE"))")
        }

        return lines
    }

    static func formatMinutes(_ value: Int64) -> String {
        if value <= 0 {
            return "0 мин"
        }

        if value >= 60 {
            let hours = value / 60
            let minutes = value % 60
            if minutes == 0 {
                return "\(hours) ч"
            }
            return "\(hours) ч \(minutes) мин"
        }

        return "\(value) мин"
    }

    private static func valueText(for value: AnalyticsPrimitiveValue, key: String) -> String {
        switch value {
        case let .string(raw):
            return raw
        case let .integer(raw):
            return formatInteger(raw, key: key)
        case let .double(raw):
            return formatDouble(raw, key: key)
        case let .bool(raw):
            return raw ? "Да" : "Нет"
        case .null:
            return "Нет данных"
        }
    }

    private static func formatInteger(_ value: Int64, key: String) -> String {
        if key.contains("MINUTES") || key.contains("DURATION") {
            return formatMinutes(value)
        }

        if key == "AVG_SLEEP_START_TIME" {
            return clockText(fromMinutes: value)
        }

        if key.contains("TIME"), value >= 0, value < 24 * 60 {
            return clockText(fromMinutes: value)
        }

        return String(value)
    }

    private static func formatDouble(_ value: Double, key: String) -> String {
        if key.contains("SCORE") {
            let percent = value <= 1 ? value * 100 : value
            return String(format: "%.0f%%", percent)
        }

        if key.contains("MINUTES") || key.contains("DURATION") {
            return formatMinutes(Int64(value.rounded()))
        }

        if key.contains("TIME"), value >= 0, value < Double(24 * 60) {
            return clockText(fromMinutes: Int64(value.rounded()))
        }

        return String(format: value.rounded() == value ? "%.0f" : "%.1f", value)
    }

    private static func clockText(fromMinutes totalMinutes: Int64) -> String {
        let normalizedMinutes = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        let hours = normalizedMinutes / 60
        let minutes = normalizedMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}
