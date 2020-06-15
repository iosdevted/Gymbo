//
//  ImagesTableViewCell.swift
//  Gymbo
//
//  Created by Rohan Sharma on 5/24/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import UIKit

protocol ImagesTableViewCellDelegate: class {
    func buttonTapped(cell: ImagesTableViewCell, index: Int, function: ButtonFunction)
}

enum ButtonFunction {
    case add
    case update
}

// MARK: - Properties
class ImagesTableViewCell: UITableViewCell {
    private let horizontalScrollView = UIScrollView()

    private var buttons = [CustomButton]()
    private var imageViews = [UIImageView]()

    private var defaultImage = UIImage()
    var images: [UIImage] {
        var images = [UIImage]()
        buttons.forEach {
            if let image = $0.image(for: .normal),
                image != defaultImage {
                images.append(image)
            }
        }
        return images
    }

    weak var imagesTableViewCellDelegate: ImagesTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }
}

// MARK: - Structs/Enums
extension ImagesTableViewCell {
    enum ImageType {
        case button
        case image
    }
}

// MARK: - ViewAdding
extension ImagesTableViewCell: ViewAdding {
    func addViews() {
        add(subviews: [horizontalScrollView])
    }

    func setupViews() {
        selectionStyle = .none
    }

    func addConstraints() {
        NSLayoutConstraint.activate([
            horizontalScrollView.topAnchor.constraint(equalTo: topAnchor),
            horizontalScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
        horizontalScrollView.layoutIfNeeded()
    }
}

// MARK: - Funcs
extension ImagesTableViewCell {
    private func setup() {
        addViews()
        setupViews()
        addConstraints()
    }

    func configure(count: Int = 2, existingImages: [UIImage?], defaultImage: UIImage?, type: ImageType) {
        /**
         - Preventing adding subviews to horizontalScrollView multiple times.
         - UIScrollView has 2 subviews (two scroll view indicators).
         */
        guard horizontalScrollView.subviews.count == 2,
            let image = defaultImage else {
            return
        }

        self.defaultImage = image

        let squareBound = frame.height * 0.9
        let viewSize = CGSize(width: squareBound, height: squareBound)
        let spacing = CGFloat(20)
        horizontalScrollView.contentSize.width = (CGFloat(count) * viewSize.width) + (CGFloat(count) * spacing)

        var previousX = CGFloat(0)
        for i in 0..<Int(count) {
            let view: UIView
            switch type {
            case .button:
                let button = CustomButton(frame:
                    CGRect(origin:
                    CGPoint(x: previousX + spacing,
                            y: 0),
                            size: viewSize))
                button.setImage(image, for: .normal)
                button.contentMode = .scaleAspectFit
                button.tag = i
                button.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
                buttons.append(button)
                view = button
            case .image:
                let imageView = UIImageView(frame:
                    CGRect(origin:
                    CGPoint(x: previousX + spacing,
                            y: 0),
                            size: viewSize))
                imageView.image = image
                imageView.contentMode = .scaleAspectFit
                imageView.layoutIfNeeded()
                imageViews.append(imageView)
                view = imageView
            }
            view.addCorner(style: .circle(view: view))
            previousX += viewSize.width + spacing
            horizontalScrollView.addSubview(view)
        }
        horizontalScrollView.layoutIfNeeded()

        guard !existingImages.isEmpty else {
            return
        }

        let endIndex = min(count, existingImages.count)
        for i in 0..<endIndex {
            let image = existingImages[i]
            if !buttons.isEmpty {
                buttons[i].setImage(image, for: .normal)
            } else if !imageViews.isEmpty {
                imageViews[i].image = image
            }
        }
    }

    func update(image: UIImage? = nil, for index: Int) {
        let imageToUse = image ?? defaultImage
        let button = buttons[index]

        UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve, animations: {
            button.setImage(imageToUse, for: .normal)
        })
    }

    @objc private func imageButtonTapped(_ sender: UIButton) {
        let function: ButtonFunction = sender.image(for: .normal) == defaultImage ? .add : .update
        imagesTableViewCellDelegate?.buttonTapped(cell: self, index: sender.tag, function: function)
    }
}
