//
//  ModalPresentationC.swift
//  Gymbo
//
//  Created by Rohan Sharma on 10/1/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Properties
final class ModalPresentationC: UIPresentationController {
    private lazy var blurredView: VisualEffectView = {
        guard let containerView = containerView else {
            return VisualEffectView()
        }

        let view = VisualEffectView(frame: containerView.bounds,
                                    style: .dark)
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismiss))
        )
        return view
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(didPan))
    }()

    var customBounds: CustomBounds?
    var showBlurredView = true
    private var hasRegisteredForKeyboardNotifications = false

    // MARK: - UIPresentationController Var/Funcs
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return CGRect.zero
        }

        if let bounds = customBounds {
            if !hasRegisteredForKeyboardNotifications {
                registerForKeyboardNotifications()
                hasRegisteredForKeyboardNotifications = true
            }
            let width = containerView.bounds.width - (2 * bounds.horizontalPadding)
            let height = containerView.bounds.height * bounds.percentHeight
            let size = CGSize(width: width, height: height)

            let x = bounds.horizontalPadding
            let y = (containerView.bounds.height - height) / 2
            let origin = CGPoint(x: x, y: y)

            return CGRect(origin: origin, size: size)
        }

        let defaultHeight = containerView.bounds.height - Constants.defaultYOffset
        return CGRect(origin: CGPoint(x: 0,
                                      y: Constants.defaultYOffset),
                      size: CGSize(width: containerView.bounds.width,
                                   height: defaultHeight))
    }

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        panGesture.delegate = self
        presentedViewController.view.addGestureRecognizer(panGesture)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()

        presentedView?.addCorner(style: .small)
        let maskedCorners: CACornerMask =
            customBounds == nil ?
            [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
            [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        presentedView?.layer.maskedCorners = maskedCorners
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView,
            let coordinator = presentingViewController.transitionCoordinator,
            showBlurredView else {
                return
        }

        blurredView.alpha = 0
        blurredView.contentView.addSubview(presentedViewController.view)
        container.addSubview(blurredView)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.blurredView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentingViewController.transitionCoordinator,
        showBlurredView else {
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ -> Void in
            self?.blurredView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed, showBlurredView {
            blurredView.removeFromSuperview()
        }
    }
}

// MARK: - Structs/Enums
private extension ModalPresentationC {
    enum Constants {
        static let animationDuration = TimeInterval(0.4)
        static let delayDuration = TimeInterval(0)

        static let defaultYOffset = CGFloat(60)
        static let dampingDuration = CGFloat(1)
        static let velocity = CGFloat(0.7)
        static let keyboardSpacing = CGFloat(10)
    }
}

// MARK: - Funcs
extension ModalPresentationC {
    @objc private func didPan(gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view,
            let presented = presentedView, let container = containerView else {
                return
        }

        let location = gestureRecognizer.translation(in: view)

        switch gestureRecognizer.state {
        case .changed:
            let offset = location.y + Constants.defaultYOffset

            if offset > frameOfPresentedViewInContainerView.origin.y {
                presented.frame.origin.y = offset
            }
        case .ended, .cancelled:
            let velocity = gestureRecognizer.velocity(in: view)
            let maxPresentedY = (container.frame.height - Constants.defaultYOffset) / 2

            if velocity.y > 600 {
                presentedViewController.dismiss(animated: true)
            } else {
                if presented.frame.origin.y < maxPresentedY {
                    resizeToFullView()
                } else {
                    presentedViewController.dismiss(animated: true)
                }
            }
        default:
            break
        }
    }

    private func resizeToFullView() {
        guard let presentedView = presentedView else {
            return
        }

        UIView.animate(withDuration: Constants.animationDuration,
                       delay: Constants.delayDuration,
                       usingSpringWithDamping: Constants.dampingDuration,
                       initialSpringVelocity: Constants.velocity,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
            guard let self = self else { return }
            presentedView.frame.origin = self.frameOfPresentedViewInContainerView.origin
        })
    }

    @objc private func dismiss() {
        presentedViewController.dismiss(animated: true)
    }
}

// MARK: - KeyboardObserving
extension ModalPresentationC: KeyboardObserving {
    func keyboardWillShow(_ notification: Notification) {
        presentedViewController.view.removeGestureRecognizer(panGesture)

        guard let keyboardHeight = notification.keyboardSize?.height,
            let presentedView = presentedView,
            let containerView = containerView else {
            return
        }

        let minYOfKeyboard = containerView.frame.height - keyboardHeight
        let heightToRemove = abs(presentedView.frame.maxY - minYOfKeyboard)
        let minYLimitOfPresentedView = presentedView.frame.origin.y / 3

        /*
         - minYLimitOfPresentedView is 1/3 of it's original origin.y
         - Need to call (2 * newYOrigin) because that's how much space should not
         be removed from the new height
        */
        guard minYOfKeyboard != presentedView.frame.maxY + Constants.keyboardSpacing else {
            return
        }

        let newFrame: CGRect
        let newOrigin =
            containerView.frame.height -
            keyboardHeight - Constants.keyboardSpacing -
            presentedView.frame.height
        // Checking to see if the new origin of presented view is >= minYLimitOfPresentedView
        if newOrigin >= minYLimitOfPresentedView {
            let y =
                containerView.frame.height -
                keyboardHeight -
                presentedView.frame.height -
                Constants.keyboardSpacing
            newFrame = CGRect(origin: CGPoint(x: presentedView.frame.origin.x,
                                              y: y),
                              size: presentedView.frame.size)
        } else {
            let height =
                presentedView.frame.height +
                (2 * minYLimitOfPresentedView) -
                heightToRemove -
                Constants.keyboardSpacing
            newFrame = CGRect(origin: CGPoint(x: presentedView.frame.origin.x,
                                              y: minYLimitOfPresentedView),
                              size: CGSize(width: presentedView.frame.width,
                                           height: height))
        }
        presentedView.frame = newFrame
        presentedView.layoutIfNeeded()
    }

    func keyboardWillHide(_ notification: Notification) {
        if let presentedView = presentedView {
            presentedView.frame = frameOfPresentedViewInContainerView
            presentedView.layoutIfNeeded()
        }
        presentedViewController.view.addGestureRecognizer(panGesture)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ModalPresentationC: UIGestureRecognizerDelegate {
    // Preventing panGesture eating up table view gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer != panGesture
    }
}
