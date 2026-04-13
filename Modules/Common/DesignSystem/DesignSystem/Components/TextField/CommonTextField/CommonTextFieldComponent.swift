import UIKit
import DesignTokens

@MainActor
public final class CommonTextField: UIView {
    public var onTextChanged: ((String) -> Void)?
    public var onReturn: (() -> Void)?

    public var text: String {
        get { textField.text ?? "" }
        set {
            textField.text = sanitize(newValue, for: configuration.kind)
            updateVisualState(animated: false)
        }
    }

    public private(set) var configuration: CommonTextFieldConfiguration

    private let contentView = UIView()
    private let hintLabel = UILabel()
    private let textField = UITextField()
    private let clearButton = UIButton(type: .system)
    private let visibilityButton = UIButton(type: .system)
    private let controlsStackView = UIStackView()
    private let bottomBorderView = UIView()
    private let errorLabel = UILabel()

    private var hintCenteredConstraints: [NSLayoutConstraint] = []
    private var hintFloatingConstraints: [NSLayoutConstraint] = []
    private var controlsWidthConstraint: NSLayoutConstraint?
    private var textFieldTopConstraint: NSLayoutConstraint?
    private var textFieldLeadingConstraint: NSLayoutConstraint?
    private var controlsTrailingConstraint: NSLayoutConstraint?
    private var textFieldTrailingConstraint: NSLayoutConstraint?
    private var bottomBorderHeightConstraint: NSLayoutConstraint?
    private var errorLabelTopConstraint: NSLayoutConstraint?
    private var isPasswordVisible = false

    public init(configuration: CommonTextFieldConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupView()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func apply(configuration: CommonTextFieldConfiguration) {
        self.configuration = configuration

        hintLabel.text = configuration.hint
        hintLabel.font = configuration.appearance.hintFont

        textField.text = sanitize(configuration.text ?? textField.text ?? "", for: configuration.kind)
        textField.textColor = configuration.appearance.textColor
        textField.font = configuration.appearance.textFont
        textField.tintColor = configuration.appearance.tintColor
        textField.isEnabled = configuration.isEnabled

        bottomBorderView.backgroundColor = configuration.appearance.borderColor
        clearButton.tintColor = configuration.appearance.hintColor
        visibilityButton.tintColor = configuration.appearance.hintColor
        errorLabel.text = configuration.errorText
        errorLabel.font = configuration.appearance.errorFont
        errorLabel.textColor = configuration.appearance.errorColor

        controlsStackView.spacing = configuration.appearance.controlsSpacing
        updateLayoutConstants()

        configureKeyboard(for: configuration.kind)
        isPasswordVisible = false
        updatePasswordVisibility()
        updateVisualState(animated: false)
    }

    public override var intrinsicContentSize: CGSize {
        let errorHeight = errorLabel.isHidden ? 0 : ceil(errorLabel.intrinsicContentSize.height) + DesignSpacing.xSmall
        return CGSize(width: UIView.noIntrinsicMetric, height: DesignSize.textFieldHeight + errorHeight)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    public func setError(message: String?) {
        configuration.errorText = message
        errorLabel.text = message
        updateVisualState(animated: false)
    }
}

private extension CommonTextField {
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.isUserInteractionEnabled = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)

        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        visibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        controlsStackView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.axis = .horizontal
        controlsStackView.alignment = .center
        controlsStackView.distribution = .fill
        controlsStackView.addArrangedSubview(visibilityButton)
        controlsStackView.addArrangedSubview(clearButton)

        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        addSubview(contentView)
        addSubview(errorLabel)
        contentView.addSubview(hintLabel)
        contentView.addSubview(textField)
        contentView.addSubview(controlsStackView)
        contentView.addSubview(bottomBorderView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        let horizontalPadding = configuration.appearance.horizontalPadding
        let topPadding = configuration.appearance.topPadding
        let bottomPadding = configuration.appearance.bottomPadding

        hintCenteredConstraints = [
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            hintLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
        ]

        hintFloatingConstraints = [
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            hintLabel.topAnchor.constraint(equalTo: topAnchor, constant: topPadding),
        ]

        controlsWidthConstraint = controlsStackView.widthAnchor.constraint(equalToConstant: 0)
        controlsWidthConstraint?.priority = .defaultHigh
        textFieldTopConstraint = textField.topAnchor.constraint(equalTo: topAnchor, constant: topPadding + DesignSize.textFieldFloatingOffset)
        textFieldLeadingConstraint = textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding)
        textFieldTrailingConstraint = textField.trailingAnchor.constraint(equalTo: controlsStackView.leadingAnchor, constant: -DesignSpacing.medium)
        controlsTrailingConstraint = controlsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding)
        bottomBorderHeightConstraint = bottomBorderView.heightAnchor.constraint(equalToConstant: DesignSize.textFieldBorderWidth / UIScreen.main.scale)
        errorLabelTopConstraint = errorLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: DesignSpacing.xSmall)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textFieldTopConstraint ?? textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topPadding + DesignSize.textFieldFloatingOffset),
            textFieldLeadingConstraint ?? textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            textFieldTrailingConstraint ?? textField.trailingAnchor.constraint(equalTo: controlsStackView.leadingAnchor, constant: -DesignSpacing.medium),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -bottomPadding),

            controlsTrailingConstraint ?? controlsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            controlsStackView.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            controlsWidthConstraint ?? controlsStackView.widthAnchor.constraint(equalToConstant: 0),

            clearButton.widthAnchor.constraint(equalToConstant: DesignSize.textFieldControlIcon),
            clearButton.heightAnchor.constraint(equalToConstant: DesignSize.textFieldControlIcon),
            visibilityButton.widthAnchor.constraint(equalToConstant: DesignSize.textFieldControlIcon),
            visibilityButton.heightAnchor.constraint(equalToConstant: DesignSize.textFieldControlIcon),

            bottomBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomBorderHeightConstraint ?? bottomBorderView.heightAnchor.constraint(equalToConstant: DesignSize.textFieldBorderWidth / UIScreen.main.scale),

            errorLabelTopConstraint ?? errorLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: DesignSpacing.xSmall),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        NSLayoutConstraint.activate(hintCenteredConstraints)
    }

    func configureKeyboard(for kind: CommonTextFieldConfiguration.InputKind) {
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textContentType = nil
        textField.keyboardType = .default
        textField.isSecureTextEntry = false
        textField.returnKeyType = .done
        textField.inputAccessoryView = nil

        switch kind {
        case .plain:
            textField.autocapitalizationType = .sentences
        case .email:
            textField.keyboardType = .emailAddress
            textField.textContentType = .emailAddress
            textField.autocapitalizationType = .none
        case .phone:
            textField.keyboardType = .phonePad
            textField.textContentType = .telephoneNumber
        case .numericCode:
            textField.keyboardType = .numberPad
            textField.textContentType = .oneTimeCode
        case .password:
            textField.isSecureTextEntry = true
            textField.textContentType = .password
        }

        if configuration.showsDoneAccessory {
            textField.inputAccessoryView = makeDoneToolbar()
        }
    }

    func updateVisualState(animated: Bool) {
        let hasText = !(textField.text ?? "").isEmpty
        let isFocused = textField.isFirstResponder
        let hasError = (configuration.errorText?.isEmpty == false)
        let showsVisibility = configuration.kind == .password
        let showsClear = configuration.showsClearButton && hasText

        clearButton.isHidden = !showsClear
        visibilityButton.isHidden = !showsVisibility
        errorLabel.isHidden = !hasError
        hintLabel.textColor = hasError ? configuration.appearance.errorColor : configuration.appearance.hintColor
        bottomBorderView.backgroundColor = hasError
            ? configuration.appearance.errorColor
            : (isFocused ? DesignColor.accent : DesignColor.secondary)
        bottomBorderHeightConstraint?.constant = borderHeight(isFocused: isFocused)

        controlsWidthConstraint?.constant = controlStackWidth(showsVisibility: showsVisibility, showsClear: showsClear)
        hintLabel.font = hasText ? configuration.appearance.floatingHintFont : configuration.appearance.hintFont
        invalidateIntrinsicContentSize()

        let updates = {
            NSLayoutConstraint.deactivate(hasText ? self.hintCenteredConstraints : self.hintFloatingConstraints)
            NSLayoutConstraint.activate(hasText ? self.hintFloatingConstraints : self.hintCenteredConstraints)
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseInOut],
                animations: updates
            )
        } else {
            updates()
        }
    }

    func updateLayoutConstants() {
        let horizontalPadding = configuration.appearance.horizontalPadding
        let topPadding = configuration.appearance.topPadding

        hintCenteredConstraints.first?.constant = horizontalPadding
        hintFloatingConstraints.first?.constant = horizontalPadding
        hintFloatingConstraints.last?.constant = topPadding
        textFieldTopConstraint?.constant = topPadding + DesignSize.textFieldFloatingOffset
        textFieldLeadingConstraint?.constant = horizontalPadding
        controlsTrailingConstraint?.constant = -horizontalPadding
    }

    func controlStackWidth(showsVisibility: Bool, showsClear: Bool) -> CGFloat {
        let buttonSize = DesignSize.textFieldControlIcon
        let spacing = configuration.appearance.controlsSpacing

        switch (showsVisibility, showsClear) {
        case (false, false):
            return 0
        case (true, true):
            return (buttonSize * 2) + spacing
        default:
            return buttonSize
        }
    }

    func borderHeight(isFocused: Bool) -> CGFloat {
        let width = isFocused ? DesignSize.textFieldFocusedBorderWidth : DesignSize.textFieldBorderWidth
        return width / UIScreen.main.scale
    }

    func updatePasswordVisibility() {
        guard configuration.kind == .password else {
            visibilityButton.setImage(nil, for: .normal)
            return
        }

        textField.isSecureTextEntry = !isPasswordVisible
        let imageName = isPasswordVisible ? "eye.slash" : "eye"
        visibilityButton.setImage(UIImage(systemName: imageName), for: .normal)

        if textField.isFirstResponder {
            let currentText = textField.text
            textField.text = nil
            textField.text = currentText
        }
    }

    func sanitize(_ text: String, for kind: CommonTextFieldConfiguration.InputKind) -> String {
        switch kind {
        case .numericCode:
            return text.filter(\.isNumber)
        case .phone:
            var didUsePlus = false
            return text.filter { character in
                if character.isNumber { return true }
                if character == "+" && !didUsePlus {
                    didUsePlus = true
                    return true
                }
                return [" ", "-", "(", ")"].contains(character)
            }
        case .plain, .email, .password:
            return text
        }
    }

    @objc
    func textDidChange() {
        let sanitizedText = sanitize(textField.text ?? "", for: configuration.kind)
        if sanitizedText != textField.text {
            textField.text = sanitizedText
        }

        if configuration.errorText != nil {
            configuration.errorText = nil
            errorLabel.text = nil
        }

        updateVisualState(animated: true)
        onTextChanged?(sanitizedText)
    }

    @objc
    func clearText() {
        textField.text = nil
        updateVisualState(animated: true)
        onTextChanged?("")
    }

    @objc
    func handleTap() {
        _ = textField.becomeFirstResponder()
    }

    @objc
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        updatePasswordVisibility()
    }

    @objc
    func handleDoneButtonTap() {
        _ = textField.resignFirstResponder()
        onReturn?()
    }

    func makeDoneToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "Done",
                style: .done,
                target: self,
                action: #selector(handleDoneButtonTap)
            ),
        ]
        return toolbar
    }
}

extension CommonTextField: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateVisualState(animated: true)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateVisualState(animated: true)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = textField.resignFirstResponder()
        onReturn?()
        return true
    }

    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard
            configuration.kind == .numericCode || configuration.kind == .phone,
            let currentText = textField.text,
            let stringRange = Range(range, in: currentText)
        else {
            return true
        }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        let sanitizedText = sanitize(updatedText, for: configuration.kind)
        return updatedText == sanitizedText
    }
}
