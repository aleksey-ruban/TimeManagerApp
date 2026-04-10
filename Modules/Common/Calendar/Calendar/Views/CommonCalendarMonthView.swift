import UIKit
import DesignTokens

@MainActor
final class CommonCalendarMonthView: UIView {
    private let monthDate: Date
    private let configuration: CommonCalendarConfiguration
    private let monthProvider: CommonCalendarMonthProviding
    private let nowProvider: @Sendable () -> Date
    private let onSelectDate: (Date) -> Void

    init(
        monthDate: Date,
        configuration: CommonCalendarConfiguration,
        monthProvider: CommonCalendarMonthProviding,
        nowProvider: @escaping @Sendable () -> Date,
        onSelectDate: @escaping (Date) -> Void
    ) {
        self.monthDate = monthDate
        self.configuration = configuration
        self.monthProvider = monthProvider
        self.nowProvider = nowProvider
        self.onSelectDate = onSelectDate
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CommonCalendarMonthView {
    func setupView() {
        let monthLabel = UILabel()
        monthLabel.font = .systemFont(ofSize: 17, weight: .medium)
        monthLabel.textAlignment = .center
        monthLabel.textColor = DesignColor.textPrimary
        monthLabel.text = monthProvider.monthTitle(for: monthDate)
        addSubview(monthLabel)

        let weekdaysStackView = UIStackView()
        weekdaysStackView.axis = .horizontal
        weekdaysStackView.distribution = .fillEqually
        addSubview(weekdaysStackView)

        ["П", "В", "С", "Ч", "П", "С", "В"].forEach { title in
            let label = UILabel()
            label.text = title
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 11, weight: .regular)
            label.textColor = DesignColor.textSecondary
            weekdaysStackView.addArrangedSubview(label)
        }

        let weeksStackView = UIStackView()
        weeksStackView.axis = .vertical
        weeksStackView.spacing = 8
        addSubview(weeksStackView)

        monthProvider.makeWeeks(for: monthDate).forEach { week in
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually

            week.forEach { dayDate in
                let dayView: UIView
                if let dayDate {
                    let button = CommonCalendarDayButton()
                    let isEnabled = monthProvider.isDateEnabled(
                        dayDate,
                        configuration: configuration,
                        now: nowProvider()
                    )
                    button.apply(
                        day: Calendar.current.component(.day, from: dayDate),
                        isSelected: Calendar.current.isDate(dayDate, inSameDayAs: configuration.selectedDate),
                        isHighlighted: configuration.highlightedDates.contains(Calendar.current.startOfDay(for: dayDate)),
                        isEnabled: isEnabled
                    )
                    if isEnabled {
                        button.onTap = { [weak self] in
                            self?.onSelectDate(dayDate)
                        }
                    }
                    dayView = button
                } else {
                    dayView = UIView()
                }
                rowStackView.addArrangedSubview(dayView)
            }

            weeksStackView.addArrangedSubview(rowStackView)
        }

        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        weekdaysStackView.translatesAutoresizingMaskIntoConstraints = false
        weeksStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: topAnchor),
            monthLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            monthLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            weekdaysStackView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 12),
            weekdaysStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            weekdaysStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            weeksStackView.topAnchor.constraint(equalTo: weekdaysStackView.bottomAnchor, constant: 10),
            weeksStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            weeksStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            weeksStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
