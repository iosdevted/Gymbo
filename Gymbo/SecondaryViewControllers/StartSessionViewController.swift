//
//  StartSessionViewController.swift
//  Gymbo
//
//  Created by Rohan Sharma on 11/18/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit
import RealmSwift

protocol TimeLabelDelegate: class {
    func updateTimeLabel()
}

class StartSessionViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet private weak var tableView: UITableView!

    class var id: String {
        return String(describing: self)
    }

    private lazy var finishButton: CustomButton = {
        let button = CustomButton(frame: CGRect(origin: .zero, size: Constants.barButtonSize))
        button.title = "Finish"
        button.titleFontSize = 15
        button.add(backgroundColor: .systemGreen)
        button.addCorner()
        button.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var timerButton: CustomButton = {
        let button = CustomButton(frame: CGRect(origin: .zero, size: Constants.barButtonSize))
        button.titleFontSize = 15
        button.add(backgroundColor: .systemBlue)
        button.addCorner()
        button.addTarget(self, action: #selector(restButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var tableHeaderView: SessionHeaderView = {
        var dataModel = SessionHeaderViewModel()
        dataModel.name = session?.name ?? Constants.namePlaceholderText
        dataModel.info = session?.info ?? Constants.infoPlaceholderText
        dataModel.textColor = .black

        let sessionTableHeaderView = SessionHeaderView()
        sessionTableHeaderView.configure(dataModel: dataModel)
        sessionTableHeaderView.isContentEditable = false
        sessionTableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        return sessionTableHeaderView
    }()

    private lazy var tableFooterView: StartSessionFooterView = {
        let startSessionFooterView = StartSessionFooterView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.bounds.width, height: Constants.tableFooterViewHeight)))
        startSessionFooterView.startSessionButtonDelegate = self
        return startSessionFooterView
    }()

    var session: Session?

    private var sessionSeconds = 0 {
        didSet {
            title = sessionSeconds.getMinutesAndSecondsString()
        }
    }
    private var sessionTimer: Timer?

    private var restTimer: Timer?
    private var totalRestTime = 0
    private var restTimeRemaining = 0 {
        didSet {
            timerButton.title = restTimeRemaining > 0 ?
            restTimeRemaining.getMinutesAndSecondsString() : 0.getMinutesAndSecondsString()
        }
    }

    private let realm = try? Realm()

    private var selectedRows = [IndexPath: Bool]()

    private let userDefault = UserDefaults.standard

    weak var timeLabelDelegate: TimeLabelDelegate?

    deinit {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
    }
}

// MARK: - Structs/Enums
private extension StartSessionViewController {
    struct Constants {
        static let timeInterval = TimeInterval(1)

        static let characterLimit = 5

        static let exerciseHeaderCellHeight = CGFloat(59)
        static let exerciseDetailCellHeight = CGFloat(40)
        static let addSetButtonCellHeight = CGFloat(50)
        static let tableFooterViewHeight = CGFloat(130)

        static let barButtonSize = CGSize(width: 80, height: 30)

        static let namePlaceholderText = "Session name"
        static let infoPlaceholderText = "No Info"

        static let SESSION_SECONDS_KEY = "sessionSeconds"
        static let REST_TOTAL_TIME_KEY = "restTotalTime"
        static let REST_REMAINING_TIME_KEY = "restRemainingTime"
    }
}

// MARK: - UIViewController Var/Funcs
extension StartSessionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        setupTableHeaderView()
        setupTableFooterView()
        startSessionTimer()
        registerForKeyboardNotifications()
        registerForApplicationNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.post(name: .refreshSessions, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Used for laying out table header and footer views
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.tableHeaderView?.layoutIfNeeded()

        tableView.tableFooterView = tableView.tableFooterView
        tableView.tableFooterView?.layoutIfNeeded()
    }
}

// MARK: - Funcs
extension StartSessionViewController {
    private func setupNavigationBar() {
        title = 0.getMinutesAndSecondsString()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Rest", style: .plain, target: self, action: #selector(restButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: finishButton)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.allowsMultipleSelection = true
        tableView.delaysContentTouches = false
        tableView.register(ExerciseHeaderTableViewCell.nib, forCellReuseIdentifier: ExerciseHeaderTableViewCell.reuseIdentifier)
        tableView.register(ExerciseDetailTableViewCell.nib, forCellReuseIdentifier: ExerciseDetailTableViewCell.reuseIdentifier)
        tableView.register(AddSetTableViewCell.nib, forCellReuseIdentifier: AddSetTableViewCell.reuseIdentifier)
    }

    private func setupTableHeaderView() {
        tableView.tableHeaderView = tableHeaderView

        NSLayoutConstraint.activate([
            tableHeaderView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            tableHeaderView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 20),
            tableHeaderView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -20),
            tableHeaderView.topAnchor.constraint(equalTo: tableView.topAnchor)
        ])
        tableView.tableHeaderView = tableView.tableHeaderView
        tableView.tableHeaderView?.layoutIfNeeded()
    }

    private func setupTableFooterView() {
        tableView.tableFooterView = tableFooterView
        tableView.tableFooterView = tableView.tableFooterView
        tableView.tableFooterView?.layoutIfNeeded()
    }

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(timeInterval: Constants.timeInterval, target: self, selector: #selector(updateSessionTime), userInfo: nil, repeats: true)
        if let timer = sessionTimer {
            // Allows it to update the navigation bar.
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func startRestTimer() {
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(timeInterval: Constants.timeInterval, target: self, selector: #selector(updateRestTime), userInfo: nil, repeats: true)
        if let timer = restTimer {
            // Allows it to update in the navigation bar.
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    @objc private func restButtonTapped() {
        let restViewController = RestViewController.loadFromXib()
        restViewController.isTimerActive = restTimer?.isValid ?? false
        restViewController.startSessionTotalRestTime = totalRestTime
        restViewController.startSessionRestTimeRemaining = restTimeRemaining
        restViewController.restTimerDelegate = self

        timeLabelDelegate = restViewController

        let modalNavigationController = UINavigationController(rootViewController: restViewController)
        modalNavigationController.modalPresentationStyle = .custom
        modalNavigationController.transitioningDelegate = self
        present(modalNavigationController, animated: true)
    }

    @objc private func finishButtonTapped() {
        presentCustomAlert(title: "Finish Session", content: "Do you want to finish the session?") { [weak self] in
            if let session = self?.session {
                for exercise in session.exercises {
                    for detail in exercise.exerciseDetails {
                        let weight = Util.formattedString(stringToFormat: detail.weight, type: .weight)
                        let reps = detail.reps ?? "--"
                        let last: String
                        if weight != "--" && reps != "--" {
                            last = "\(reps) x \(weight)"
                        } else {
                            last = "--"
                        }
                        try? self?.realm?.write {
                            detail.last = last
                        }
                    }
                }
            }
            self?.dismiss(animated: true)
        }
    }

    @objc private func updateSessionTime() {
        sessionSeconds += 1
    }

    @objc private func updateRestTime() {
        restTimeRemaining -= 1
        timeLabelDelegate?.updateTimeLabel()

        if restTimeRemaining == 0 {
            ended()
        }
    }
}

// MARK: - UITableViewDataSource
extension StartSessionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let session = session else {
            presentCustomAlert(content: "Could not start session.", usesBothButtons: false, rightButtonTitle: "Sounds good") {
                // No op
            }
            return 0
        }
        return session.exercises.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let session = session else {
            presentCustomAlert(content: "Could not start session.", usesBothButtons: false, rightButtonTitle: "Sounds good") {
                // No op
            }
            return 0
        }

        // Adding 1 for exercise name label
        // Adding 1 for "+ Set button"
        return session.exercises[section].sets + 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let session = session else {
            presentCustomAlert(content: "Could not start session.", usesBothButtons: false, rightButtonTitle: "Sounds good") {
                // No op
            }
            return UITableViewCell()
        }
        
        switch indexPath.row {
        case 0: // Exercise header cell
            if let exerciseHeaderCell = tableView.dequeueReusableCell(withIdentifier: ExerciseHeaderTableViewCell.reuseIdentifier, for: indexPath) as? ExerciseHeaderTableViewCell {
                var dataModel = ExerciseHeaderTableViewCellModel()
                dataModel.name = session.exercises[indexPath.section].name
                dataModel.isDoneButtonImageHidden = false

                exerciseHeaderCell.configure(dataModel: dataModel)
                exerciseHeaderCell.exerciseHeaderCellDelegate = self
                return exerciseHeaderCell
            }
        case tableView.numberOfRows(inSection: indexPath.section) - 1: // Add set cell
            if let addSetCell = tableView.dequeueReusableCell(withIdentifier: AddSetTableViewCell.reuseIdentifier, for: indexPath) as? AddSetTableViewCell {
                addSetCell.addSetTableViewCellDelegate = self

                return addSetCell
            }
        default: // Exercise detail cell
            if let exerciseDetailCell = tableView.dequeueReusableCell(withIdentifier: ExerciseDetailTableViewCell.reuseIdentifier, for: indexPath) as? ExerciseDetailTableViewCell {
                var dataModel = ExerciseDetailTableViewCellModel()
                dataModel.sets = "\(indexPath.row)"
                dataModel.last = session.exercises[indexPath.section].exerciseDetails[indexPath.row - 1].last ?? "--"
                dataModel.reps = session.exercises[indexPath.section].exerciseDetails[indexPath.row - 1].reps
                dataModel.weight = session.exercises[indexPath.section].exerciseDetails[indexPath.row - 1].weight
                dataModel.isDoneButtonEnabled = true

                exerciseDetailCell.configure(dataModel: dataModel)
                exerciseDetailCell.exerciseDetailCellDelegate = self
                exerciseDetailCell.didSelect = selectedRows[indexPath] != nil
                return exerciseDetailCell
            }
        }

        presentCustomAlert(content: "Could not start session.", usesBothButtons: false, rightButtonTitle: "Sounds good") {
            // No op
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.row {
        // Protecting the first, second, and last rows because they shouldn't be swipe to delete
        case 0, tableView.numberOfRows(inSection: indexPath.section) - 1:
            return false
        case 1:
            return (session?.exercises[indexPath.section].sets ?? 0) > 1
        default:
            return true
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _,_, completion in
            try? self?.realm?.write {
                self?.removeSet(indexPath: indexPath)
            }
            self?.selectedRows[indexPath] = nil
            DispatchQueue.main.async {
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadSections([indexPath.section], with: .none)
            }
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    private func removeSet(indexPath: IndexPath) {
        guard let session = session else {
            return
        }

        session.exercises[indexPath.section].sets -= 1
        session.exercises[indexPath.section].exerciseDetails.remove(at: indexPath.row - 1)
    }
}

// MARK: - UITableViewDelegate
extension StartSessionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return Constants.exerciseHeaderCellHeight
        case tableView.numberOfRows(inSection: indexPath.section) - 1:
            return Constants.addSetButtonCellHeight
        default:
            return Constants.exerciseDetailCellHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let exerciseDetailCell = tableView.cellForRow(at: indexPath) as? ExerciseDetailTableViewCell else {
            return
        }

        selectedRows[indexPath] = true
        exerciseDetailCell.didSelect = true
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let exerciseDetailCell = tableView.cellForRow(at: indexPath) as? ExerciseDetailTableViewCell else {
            return
        }

        selectedRows[indexPath] = nil
        exerciseDetailCell.didSelect = false
    }
}

// MARK: - ExerciseHeaderCellDelegate
extension StartSessionViewController: ExerciseHeaderCellDelegate {
    func deleteExerciseButtonTapped(cell: ExerciseHeaderTableViewCell) {
        guard let section = tableView.indexPath(for: cell)?.section else {
            return
        }

        try? realm?.write {
            session?.exercises.remove(at: section)
        }
        tableView.deleteSections(IndexSet(integer: section), with: .automatic)
    }
}

// MARK: - ExerciseDetailTableViewCellDelegate
extension StartSessionViewController: ExerciseDetailTableViewCellDelegate {
    func shouldChangeCharactersInTextField(textField: UITextField, replacementString string: String) -> Bool {
        let totalString = "\(textField.text ?? "")\(string)"
        return totalString.count <= Constants.characterLimit // Need a constant for this
    }

    func textFieldDidEndEditing(textField: UITextField, textFieldType: TextFieldType, cell: ExerciseDetailTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            NSLog("Found nil index path for text field after it ended editing.")
            return
        }

        let text = textField.text ?? "--"
        // Decrementing indexPath.row by 1 because the first cell is the exercise header cell
        try? realm?.write {
            saveTextFieldData(text, textFieldType: textFieldType, section: indexPath.section, row: indexPath.row - 1)
        }
    }

    private func saveTextFieldData(_ text: String, textFieldType: TextFieldType, section: Int, row: Int) {
        switch textFieldType {
        case .reps:
            session?.exercises[section].exerciseDetails[row].reps = text
        case .weight:
            session?.exercises[section].exerciseDetails[row].weight = text
        }
    }
}

// MARK: - AddSetTableViewCellDelegate
extension StartSessionViewController: AddSetTableViewCellDelegate {
    func addSetButtonTapped(cell: AddSetTableViewCell) {
        guard let section = tableView.indexPath(for: cell)?.section,
              let session = session else {
            return
        }

        try? realm?.write {
            addSet(section: section)
        }

        UIView.performWithoutAnimation {
            tableView.reloadSections([section], with: .none)
        }
        let sets = session.exercises[section].sets
        tableView.scrollToRow(at: IndexPath(row: sets + 1, section: section), at: .none, animated: true)
    }

    private func addSet(section: Int) {
        session?.exercises[section].sets += 1
        session?.exercises[section].exerciseDetails.append(ExerciseDetails())
    }
}

// MARK: - ExerciseListDelegate
extension StartSessionViewController: ExerciseListDelegate {
    func updateExerciseList(_ exerciseTextList: [ExerciseText]) {
        for exerciseText in exerciseTextList {
            let newExercise = Exercise(name: exerciseText.exerciseName, muscleGroups: exerciseText.exerciseMuscles, sets: 1, exerciseDetails: List<ExerciseDetails>())
            try? realm?.write {
                session?.exercises.append(newExercise)
            }
        }
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
}

// MARK: - StartSessionButtonDelegate
extension StartSessionViewController: StartSessionButtonDelegate {
    func addExercise() {
        let storyboard = mainStoryboard()
        guard let exercisesViewController = storyboard.instantiateViewController(withIdentifier: ExercisesViewController.id) as? ExercisesViewController else {
            return
        }

        exercisesViewController.state = .noBarButtons
        exercisesViewController.exerciseListDelegate = self
        navigationController?.pushViewController(exercisesViewController, animated: true)
        if #available(iOS 13.0, *) {
            // No op
            // In iOS >= 13, the title stays updating
        } else {
            title = ""
        }
    }

    func cancelSession() {
        presentCustomAlert(title: "Cancel Session", content: "Do you want to cancel") { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - RestTimerDelegate
extension StartSessionViewController: RestTimerDelegate {
    func started(totalTime: Int) {
        totalRestTime = totalTime
        restTimeRemaining = totalRestTime
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timerButton)
        timerButton.addMovingLayerAnimation(duration: restTimeRemaining)

        startRestTimer()
    }

    func timeUpdated(totalTime: Int, timeRemaining: Int) {
        totalRestTime = totalTime
        restTimeRemaining = timeRemaining

        timerButton.addMovingLayerAnimation(duration: restTimeRemaining, totalTime: totalRestTime, timeRemaining: restTimeRemaining)
    }

    func ended() {
        restTimer?.invalidate()
        timerButton.removeMovingLayerAnimation()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Rest", style: .plain, target: self, action: #selector(restButtonTapped))

        // In case this timer finishes first.
        presentedViewController?.dismiss(animated: true)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension StartSessionViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let modalPresentationController = ModalPresentationController(presentedViewController: presented, presenting: presenting)
        modalPresentationController.customBounds = CustomBounds(horizontalPadding: 20, percentHeight: 0.7)
        return modalPresentationController
    }
}

// MARK: - KeyboardObserving
extension StartSessionViewController: KeyboardObserving {
    func keyboardWillShow(_ notification: Notification) {
        guard let keyboardHeight = notification.keyboardSize?.height else {
            return
        }

        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.contentInset.bottom = keyboardHeight
        }
    }

    func keyboardWillHide(_ notification: Notification) {
        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.contentInset = .zero
        }
    }
}

// MARK: - ApplicationStateObserving
extension StartSessionViewController: ApplicationStateObserving {
    func didEnterBackground(_ notification: Notification) {
        sessionTimer?.invalidate()
        restTimer?.invalidate()

        let timeDictionary: [String: Int] = [
            Constants.SESSION_SECONDS_KEY: sessionSeconds,
            Constants.REST_TOTAL_TIME_KEY: totalRestTime,
            Constants.REST_REMAINING_TIME_KEY: restTimeRemaining
        ]

        userDefault.set(Date(), forKey: UserDefaultKeys.STARTSESSION_DATE)
        userDefault.set(timeDictionary, forKey: UserDefaultKeys.STARTSESSION_TIME_DICTIONARY)
    }

    func willEnterForeground(_ notification: Notification) {
        if let date = userDefault.object(forKey: UserDefaultKeys.STARTSESSION_DATE) as? Date,
            let timeDictionary = userDefault.object(forKey: UserDefaultKeys.STARTSESSION_TIME_DICTIONARY) as? [String: Int] {

            let secondsElapsed = Int(Date().timeIntervalSince(date))

            sessionSeconds += secondsElapsed
            startSessionTimer()

            let restTotalTime = timeDictionary[Constants.REST_TOTAL_TIME_KEY] ?? 0
            let restRemainingTime = timeDictionary[Constants.REST_REMAINING_TIME_KEY] ?? 0
            let newTimeRemaining = restRemainingTime - secondsElapsed

            if newTimeRemaining > 0 {
                totalRestTime = restTotalTime
                restTimeRemaining = newTimeRemaining
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timerButton)
                timerButton.addMovingLayerAnimation(duration: restTimeRemaining, totalTime: totalRestTime, timeRemaining: restTimeRemaining)

                startRestTimer()
            } else {
                timerButton.removeMovingLayerAnimation()
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Rest", style: .plain, target: self, action: #selector(restButtonTapped))
            }
        }
    }
}
