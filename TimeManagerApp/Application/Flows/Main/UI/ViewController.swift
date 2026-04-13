//
//  ViewController.swift
//  TimeManagerApp
//
//  Created by Aleksey Ruban on 30.03.2026.
//

import UIKit
import DesignSystem
import DesignTokens

@MainActor
final class ViewController: UIViewController {
    private enum Cooldown {
        static let seconds = 5
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Common / TextField Demo"
        label.font = DesignTypography.displaySemibold32.font
        label.textColor = DesignColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Демонстрация интеграции поля в экран: ввод, очистка, secure-режим и получение данных из формы."
        label.font = DesignTypography.bodyRegular15.font
        label.textColor = DesignColor.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let fieldsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = DesignSpacing.xLarge + DesignSpacing.small
        return stackView
    }()

    private let plainField = CommonTextField(
        configuration: .init(
            hint: "Text value",
            kind: .plain
        )
    )

    private let numericField = CommonTextField(
        configuration: .init(
            hint: "Numeric code",
            kind: .numericCode
        )
    )

    private let passwordField = CommonTextField(
        configuration: .init(
            hint: "Password",
            kind: .password
        )
    )

    private let resultCardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = DesignColor.backgroundSecondary
        view.layer.cornerRadius = 16
        return view
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DesignTypography.bodyRegular15.font
        label.textColor = DesignColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let floatingBottomContainer = FloatingBottomContainer(
        configuration: .init(
            primaryButton: .init(
                title: "Read Form Values",
                isEnabled: false
            ),
            secondaryButton: .init(
                title: "Forgot password?"
            )
        )
    )

    private var cooldownTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindFields()
        bindButton()
        bindLinkButton()
        updateResult(reason: "Initial state")
    }

    private func setupUI() {
        view.backgroundColor = DesignColor.backgroundPrimary

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(fieldsStackView)
        contentView.addSubview(resultCardView)
        resultCardView.addSubview(resultLabel)
        view.addSubview(floatingBottomContainer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSpacing.large),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSpacing.large),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSpacing.xLarge),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSpacing.small),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            fieldsStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: DesignSpacing.xxLarge),
            fieldsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            fieldsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            resultCardView.topAnchor.constraint(equalTo: fieldsStackView.bottomAnchor, constant: DesignSpacing.xxLarge),
            resultCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            resultCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            resultLabel.topAnchor.constraint(equalTo: resultCardView.topAnchor, constant: DesignSpacing.regular),
            resultLabel.leadingAnchor.constraint(equalTo: resultCardView.leadingAnchor, constant: DesignSpacing.regular),
            resultLabel.trailingAnchor.constraint(equalTo: resultCardView.trailingAnchor, constant: -DesignSpacing.regular),
            resultLabel.bottomAnchor.constraint(equalTo: resultCardView.bottomAnchor, constant: -DesignSpacing.regular),

            contentView.bottomAnchor.constraint(
                equalTo: resultCardView.bottomAnchor,
                constant: DesignSize.primaryButtonHeight
                    + DesignSize.linkButtonHeight
                    + DesignSpacing.medium
                    + DesignSpacing.xxLarge
                    + DesignSize.floatingBottomContainerRoundedScreenBottomInset
            ),

            floatingBottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            floatingBottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            floatingBottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        makeDemoFields().forEach(fieldsStackView.addArrangedSubview(_:))
    }

    private func bindFields() {
        plainField.onTextChanged = { [weak self] _ in
            self?.updateFormState(reason: "Plain text changed")
        }

        numericField.onTextChanged = { [weak self] _ in
            self?.updateFormState(reason: "Numeric code changed")
        }

        passwordField.onTextChanged = { [weak self] _ in
            self?.updateFormState(reason: "Password changed")
        }
    }

    private func bindButton() {
        floatingBottomContainer.primaryButton?.onTap = { [weak self] in
            self?.handleCollectTap()
        }
    }

    private func bindLinkButton() {
        floatingBottomContainer.secondaryButton?.onTap = { [weak self] in
            self?.updateResult(reason: "Link button tapped")
        }
    }

    private func makeDemoFields() -> [UIView] {
        [
            makeFieldSection(
                title: "Text field",
                description: "Обычный текстовый ввод. Placeholder поднимается вверх после ввода, справа доступна очистка.",
                field: plainField
            ),
            makeFieldSection(
                title: "Numeric field",
                description: "Поле цифрового кода. Разрешены только цифры, всё лишнее компонент отсекает.",
                field: numericField
            ),
            makeFieldSection(
                title: "Password field",
                description: "Secure-режим с возможностью показать пароль через eye icon и очистить значение справа.",
                field: passwordField
            ),
        ]
    }

    private func makeFieldSection(title: String, description: String, field: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTypography.bodyMedium17.font
        titleLabel.textColor = DesignColor.textPrimary
        titleLabel.text = title

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = DesignTypography.labelRegular13.font
        descriptionLabel.textColor = DesignColor.textSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = description

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, field])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = DesignSpacing.small

        return stackView
    }

    private func updateFormState(reason: String) {
        let canReadForm = [plainField.text, numericField.text, passwordField.text]
            .contains { $0.isEmpty == false }

        floatingBottomContainer.primaryButton?.isEnabled = canReadForm
        updateResult(reason: reason)
    }

    private func handleCollectTap() {
        cooldownTask?.cancel()
        floatingBottomContainer.primaryButton?.isEnabled = false
        updateResult(reason: "Collected current form values")

        cooldownTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Cooldown.seconds))
            await MainActor.run {
                self?.updateFormState(reason: "Cooldown finished")
            }
        }
    }

    private func updateResult(reason: String) {
        resultLabel.text = """
        Reason: \(reason)

        Text: \(plainField.text)
        Numeric: \(numericField.text)
        Password length: \(passwordField.text.count)
        """
    }

    deinit {
        cooldownTask?.cancel()
    }
}
