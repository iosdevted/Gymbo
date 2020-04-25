//
//  AddSetTableViewCell.swift
//  Gymbo
//
//  Created by Rohan Sharma on 11/14/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit

protocol AddSetTableViewCellDelegate: class {
    func addSetButtonTapped(cell: AddSetTableViewCell)
}

// MARK: - Properties
class AddSetTableViewCell: UITableViewCell {
    class var reuseIdentifier: String {
        return String(describing: self)
    }

    private var addSetButton = CustomButton(frame: .zero)

    weak var addSetTableViewCellDelegate: AddSetTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }
}

// MARK: - ViewAdding
extension AddSetTableViewCell: ViewAdding {
    func addViews() {
        add(subViews: [addSetButton])
    }

    func setupViews() {
        selectionStyle = .none

        addSetButton.title = "+ Set"
        addSetButton.titleFontSize = 15
        addSetButton.add(backgroundColor: .lightGray)
        addSetButton.addCorner()
        addSetButton.addTarget(self, action: #selector(addSetButtonTapped), for: .touchUpInside)
    }

    func addConstraints() {
        NSLayoutConstraint.activate([
            addSetButton.safeAreaLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5),
            addSetButton.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            addSetButton.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addSetButton.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -15)
        ])
    }
}

// MARK: - Funcs
extension AddSetTableViewCell {
    private func setup() {
        addViews()
        setupViews()
        addConstraints()
    }

    @objc private func addSetButtonTapped(_ sender: Any) {
        addSetTableViewCellDelegate?.addSetButtonTapped(cell: self)
    }
}
