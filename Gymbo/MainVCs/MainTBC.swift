//
//  MainTBC.swift
//  Gymbo
//
//  Created by Rohan Sharma on 7/1/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit
import RealmSwift

// MARK: - Properties
class MainTBC: UITabBarController {
    var isSessionInProgress = false

    private var selectedTab = Tab.sessions

    private var isReplacingSession = false
    private var sessionToReplace: Session?

    private var realm: Realm? {
        try? Realm()
    }
}

// MARK: - Structs/Enums
extension MainTBC {
    private struct Constants {
        static let defaultYOffset = CGFloat(60)
    }

    //swiftlint:disable:next type_name
    enum Tab: Int {
        case profile
        case dashboard
        case sessions
        case exercises
        case stopwatch

        var title: String {
            let text: String
            switch self {
            case .profile:
                text = "Profile"
            case .dashboard:
                text = "Dashboard"
            case .sessions:
                text = "Sessions"
            case .exercises:
                text = "My Exercises"
            case .stopwatch:
                text = "Stopwatch"
            }
            return text
        }

        var image: UIImage {
            let imageName: String
            switch self {
            case .profile:
                imageName = "profile"
            case .dashboard:
                imageName = "dashboard"
            case .sessions:
                imageName = "dumbbell"
            case .exercises:
                imageName = "my_exercises"
            case .stopwatch:
                imageName = "stopwatch"
            }
            return UIImage(named: imageName) ?? UIImage()
        }
    }

    enum SessionState {
        case start
        case end
    }
}

// MARK: - UITabBarController Var/Funcs
extension MainTBC {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showOnboardingIfNeeded()
        resumeStartedSession()
    }
}

// MARK: - Funcs
extension MainTBC {
    private func setupTabBar() {
        delegate = self

        tabBar.backgroundColor = .dynamicWhite
        tabBar.barTintColor = .dynamicWhite
        // Color of selected item
        tabBar.unselectedItemTintColor = .dynamicDarkTabItem
        // Prevents tab bar color from being lighter than intended
        tabBar.backgroundImage = UIImage()

        let profileTab = Tab.profile
        let profileVC = ProfileVC()
        profileVC.tabBarItem = UITabBarItem(title: profileTab.title,
                                            image: profileTab.image,
                                            tag: profileTab.rawValue)

        // Need to initialize a UICollectionView with a UICollectionViewLayout
        let dashboardTab = Tab.dashboard
        let dashboardCVC = VCFactory.makeDashboardCVC(
            layout: UICollectionViewFlowLayout())
        dashboardCVC.tabBarItem = UITabBarItem(title: dashboardTab.title,
                                              image: dashboardTab.image,
                                              tag: dashboardTab.rawValue)

        let sessionsTab = Tab.sessions
        let sessionsCVC = SessionsCVC(
            collectionViewLayout: UICollectionViewFlowLayout())
        sessionsCVC.tabBarItem = UITabBarItem(title: sessionsTab.title,
                                              image: sessionsTab.image,
                                              tag: sessionsTab.rawValue)

        let exercisesTab = Tab.exercises
        let exercisesTVC = VCFactory.makeExercisesTVC(
            style: .grouped)
        exercisesTVC.tabBarItem = UITabBarItem(title: exercisesTab.title,
                                               image: exercisesTab.image,
                                               tag: exercisesTab.rawValue)

        let stopwatchTab = Tab.stopwatch
        let stopwatchVC = StopwatchVC()
        stopwatchVC.tabBarItem = UITabBarItem(title: stopwatchTab.title,
                                              image: stopwatchTab.image,
                                              tag: stopwatchTab.rawValue)

        viewControllers = [profileVC,
                           dashboardCVC,
                           sessionsCVC,
                           exercisesTVC,
                           stopwatchVC].map {
            MainNC(rootVC: $0)
        }
        selectedIndex = selectedTab.rawValue
    }

    private func showOnboardingIfNeeded() {
        if UserDataModel.shared.isFirstTimeLoad {
            let onboardingVC = OnboardingVC()
            onboardingVC.modalPresentationStyle = .overCurrentContext
            onboardingVC.modalTransitionStyle = .crossDissolve
            present(onboardingVC, animated: true)
        }
    }

    private func updateSessionProgressObservingViewControllers(state: SessionState,
                                                               endType: EndType = .cancel) {
        viewControllers?.forEach {
            if let viewControllers = ($0 as? UINavigationController)?.viewControllers,
               let viewController = viewControllers.first as? SessionProgressDelegate {
                switch state {
                case .start:
                    viewController.sessionDidStart(nil)
                case .end:
                    viewController.sessionDidEnd(nil, endType: endType)
                }
            }
        }
    }

    private func startSession(_ session: Session?) {
        isSessionInProgress = true
        updateSessionProgressObservingViewControllers(state: .start)

        let dimmedView = UIView(frame: view.frame)
        dimmedView.backgroundColor = .dimmedBackgroundBlack

        let height = view.frame.height - Constants.defaultYOffset
        let shadowContainerView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: view.frame.height),
                                                       size: CGSize(width: view.frame.width,
                                                                    height: height)))
        shadowContainerView.addShadow(direction: .up)
        shadowContainerView.hideShadow()

        let startSessionTVC = StartSessionTVC()
        startSessionTVC.session = session
        startSessionTVC.sessionProgresssDelegate = self
        startSessionTVC.dimmedView = dimmedView
        startSessionTVC.panView = shadowContainerView
        startSessionTVC.initialTabBarFrame = tabBar.frame
        // This allows startSessionViewController to extend over the bottom tab bar
        startSessionTVC.extendedLayoutIncludesOpaqueBars = true

        let containerNavigationController = MainNC(rootVC: startSessionTVC)
        containerNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        containerNavigationController.view.addCorner(style: .small)

        shadowContainerView.addSubview(containerNavigationController.view)
        containerNavigationController.view.autoPinSafeEdges(to: shadowContainerView)

        view.insertSubview(shadowContainerView, belowSubview: tabBar)
        addChild(containerNavigationController)
        containerNavigationController.didMove(toParent: self)

        view.insertSubview(dimmedView, belowSubview: shadowContainerView)
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.4,
                       delay: 0.1,
                       animations: { [weak self] in
            guard let self = self else { return }

            shadowContainerView.frame.origin = CGPoint(x: 0, y: Constants.defaultYOffset)
            self.tabBar.frame.origin = CGPoint(x: 0, y: self.view.frame.height)
        })

        if sessionToReplace != nil {
            sessionToReplace = nil
        }
    }

    private func resumeStartedSession() {
        guard let startedSession = realm?.objects(StartedSession.self).first else {
            return
        }

        let sessionToStart = Session(name: startedSession.name,
                                     info: startedSession.info,
                                     exercises: startedSession.exercises)
        startSession(sessionToStart)
    }

    private func saveCompletedSessionData(session: Session?, endType: EndType) {
        guard let session = session else {
            return
        }

        switch endType {
        case .cancel:
            try? realm?.write {
                UserDataModel.shared.user?
                    .canceledExercises.append(objectsIn: session.exercises)
            }
        case .finish:
            try? realm?.write {
                UserDataModel.shared.user?
                    .finishedExercises.append(objectsIn: session.exercises)
            }
        }
    }
}

// MARK: - SessionProgressDelegate
extension MainTBC: SessionProgressDelegate {
    func sessionDidStart(_ session: Session?) {
        if isSessionInProgress {
            guard let navigationController = (children.last as? UINavigationController),
                  let startSessionTVC = navigationController
                    .viewControllers.first as? StartSessionTVC else {
                return
            }

            let alertData = AlertData(title: "Another One?",
                                      content: "You already have a workout in progress!",
                                      usesBothButtons: true,
                                      leftButtonTitle: "I'll finish this one!",
                                      rightButtonTitle: "Start New Workout",
                                      rightButtonAction: { [weak self] in
                                        self?.isReplacingSession = true
                                        self?.sessionToReplace = session

                                        DispatchQueue.main.async {
                                            startSessionTVC.dismissAsChildViewController(
                                                endType: .cancel)
                                        }
                                      })
            presentCustomAlert(alertData: alertData)
        } else {
            startSession(session)
        }
    }

    func sessionDidEnd(_ session: Session?, endType: EndType) {
        isSessionInProgress = false

        saveCompletedSessionData(session: session,
                                 endType: endType)

        if isReplacingSession, sessionToReplace != nil {
            isReplacingSession = false
            startSession(sessionToReplace)
        } else {
            updateSessionProgressObservingViewControllers(state: .end,
                                                          endType: endType)
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTBC: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController,
                                 didSelect viewController: UIViewController) {
        selectedTab = Tab(rawValue: selectedIndex) ?? .sessions
    }
}
