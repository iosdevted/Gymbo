//
//  SessionHV.swift
//  Gymbo
//
//  Created by Rohan Sharma on 11/21/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Properties
class SessionHV: UIView {
    private let firstTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.xLarge.medium
        textView.returnKeyType = .next
        textView.tag = 0
        return textView
    }()

    private let secondTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.medium.medium
        textView.tag = 1
        return textView
    }()

    var firstText: String? {
        firstTextView.text
    }

    var secondText: String {
        secondTextView.text
    }

    var isFirstTextValid: Bool {
        firstTextView.textColor != .secondaryText && !firstTextView.text.isEmpty
    }

    var isContentEditable = true {
        didSet {
            firstTextView.isEditable = isContentEditable
            secondTextView.isEditable = isContentEditable
        }
    }

    private var textViews = [UITextView]()

    weak var customTextViewDelegate: CustomTextViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not using storyboards")
    }
}

// MARK: - UIView Var/Funcs
extension SessionHV {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupColors()
    }
}

// MARK: - ViewAdding
extension SessionHV: ViewAdding {
    func addViews() {
        add(subviews: [firstTextView, secondTextView])
    }

    func setupViews() {
        textViews = [firstTextView, secondTextView]
        for textView in textViews {
            textView.backgroundColor = .clear
            textView.isSelectable = false
            textView.isScrollEnabled = false
            textView.isEditable = true
            textView.textContainer.lineBreakMode = .byWordWrapping
            textView.autocorrectionType = .no
            textView.delegate = self
        }
        textViews.first?.layer.roundTopCorners(style: .small)
        textViews.last?.layer.roundBottomCorners(style: .small)
    }

    func setupColors() {
        backgroundColor = .clear
    }

    func addConstraints() {
        NSLayoutConstraint.activate([
            firstTextView.top.constraint(equalTo: top),
            firstTextView.leading.constraint(
                equalTo: leading,
                constant: 16),
            firstTextView.trailing.constraint(
                equalTo: trailing,
                constant: -20),
            firstTextView.bottom.constraint(equalTo: secondTextView.top),

            secondTextView.leading.constraint(
                equalTo: leading,
                constant: 16),
            secondTextView.trailing.constraint(
                equalTo: trailing,
                constant: -20),
            secondTextView.bottom.constraint(
                equalTo: bottom,
                constant: -15)
        ])
    }
}

// MARK: - Funcs
extension SessionHV {
    private func setup() {
        addViews()
        setupViews()
        setupColors()
        addConstraints()
    }

    func configure(dataModel: SessionHeaderViewModel) {
        firstTextView.text = dataModel.firstText
        secondTextView.text = dataModel.secondText
        firstTextView.textColor = dataModel.textColor
        secondTextView.textColor = dataModel.textColor
    }
}

// MARK: - UITextViewDelegate
extension SessionHV: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        customTextViewDelegate?.textViewDidChange(textView, cell: nil)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        customTextViewDelegate?.textViewDidBeginEditing(textViews[textView.tag], cell: nil)
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        guard text == "\n" else {
            return true
        }

        switch textView.tag {
        case 0:
            textView.resignFirstResponder()
            secondTextView.becomeFirstResponder()
            return false
        case 1:
            break
        default:
            break
        }
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        customTextViewDelegate?.textViewDidEndEditing(textViews[textView.tag], cell: nil)
    }
}
