//
//  ImagesTVCell.swift
//  Gymbo
//
//  Created by Rohan Sharma on 5/24/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Properties
class ImagesTVCell: RoundedTVCell {
    private let horizontalScrollView = UIScrollView()
    private var views = [UIView]()

    private var defaultImage = UIImage()

    var images: [UIImage] {
        var images = [UIImage]()
        views.forEach {
            if let button = $0 as? UIButton,
               let buttonImage = button.image(for: .normal),
                  buttonImage != defaultImage {
                images.append(buttonImage)
            } else if let imageView = $0 as? UIImageView,
                      let imageViewImage = imageView.image,
                      imageViewImage != defaultImage {
                images.append(imageViewImage)
            }
        }
        return images
    }

    weak var imageButtonDelegate: ImageButtonDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("Not using storyboards")
    }
}

// MARK: - ViewAdding
extension ImagesTVCell: ViewAdding {
    func addViews() {
        roundedView.add(subviews: [horizontalScrollView])
    }

    func addConstraints() {
        horizontalScrollView.autoPinEdges(to: roundedView)
        horizontalScrollView.layoutIfNeeded()
    }
}

// MARK: - Funcs
extension ImagesTVCell {
    private func setup() {
        addViews()
        addConstraints()
    }

    private func setupHorizontalScrollView(count: Int,
                                           imageType: ImageRepresentationType,
                                           image: UIImage) {
        let squareBound = frame.height - 20
        let viewSize = CGSize(width: squareBound, height: squareBound)
        let spacing = CGFloat(20)
        horizontalScrollView.contentSize.width =
            (CGFloat(count) * viewSize.width) +
            (CGFloat(count) * spacing)

        var previousX = CGFloat(0)
        for i in 0..<Int(count) {
            let view: UIView
            let origin = CGPoint(x: previousX + spacing,
                                 y: 10)
            let frame = CGRect(origin: origin,
                               size: viewSize)

            switch imageType {
            case .button:
                let button = CustomButton(frame: frame)
                button.setImage(image, for: .normal)
                button.contentMode = .scaleAspectFit
                button.tag = i
                button.addTarget(self, action: #selector(imageButtonTapped), for: .touchUpInside)
                view = button
            case .image:
                let imageView = UIImageView(frame: frame)
                imageView.image = image
                imageView.contentMode = .scaleAspectFit
                imageView.layoutIfNeeded()
                view = imageView
            }
            views.append(view)
            view.addCorner(style: .circle(length: view.frame.height))
            previousX += viewSize.width + spacing
            horizontalScrollView.addSubview(view)
        }
        horizontalScrollView.layoutIfNeeded()
    }

    func configure(count: Int = 2,
                   existingImages: [UIImage?],
                   defaultImage: UIImage?,
                   type: ImageRepresentationType) {
        /*
         - Preventing adding subviews to horizontalScrollView multiple times.
         - UIScrollView has 2 subviews (two scroll view indicators).
         */
        guard horizontalScrollView.subviews.count == 2,
            let image = defaultImage else {
            return
        }

        self.defaultImage = image

        setupHorizontalScrollView(count: count, imageType: type, image: image)

        guard !existingImages.isEmpty else {
            return
        }

        let endIndex = min(count, existingImages.count)
        for i in 0..<endIndex {
            let image = existingImages[i]
            let view = views[i]

            if let button = view as? CustomButton {
                button.setImage(image, for: .normal)
            } else if let imageView = view as? UIImageView {
                imageView.image = image
            }
        }
    }

    func update(image: UIImage? = nil, for index: Int) {
        let imageToUse = image ?? defaultImage
        let view = views[index]

        UIView.transition(with: view,
                          duration: .defaultAnimationTime,
                          options: .transitionCrossDissolve,
                          animations: {
            if let button = view as? CustomButton {
                button.setImage(imageToUse, for: .normal)
            } else if let imageView = view as? UIImageView {
                imageView.image = imageToUse
            }
        })
    }

    @objc private func imageButtonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }

        let function: ButtonFunction = button.image(for: .normal) == defaultImage ? .add : .update
        imageButtonDelegate?.buttonTapped(cell: self, index: button.tag, function: function)
    }
}
