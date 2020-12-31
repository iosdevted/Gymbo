//
//  CreateEditSessionTVC.swift
//  Gymbo
//
//  Created by Rohan Sharma on 11/3/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import RealmSwift

// MARK: - Properties
class CreateEditSessionTVC: UITableViewController {
    private let tableHeaderView = SessionHeaderView()
    private var didLayoutTableHeaderView = false

    private var realm: Realm? {
        try? Realm()
    }

    var customDataSource: CreateEditSessionTVDS?
    var customDelegate: CreateEditSessionTVD?
    var exercisesTVDS: ExercisesTVDS?
}

// MARK: - Structs/Enums
private extension CreateEditSessionTVC {
    struct Constants {
        static let namePlaceholderText = "Session name"
        static let infoPlaceholderText = "Info"
    }
}

// MARK: - UIViewController Var/Funcs
extension CreateEditSessionTVC {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupViews()
        setupColors()
        addConstraints()
        registerForKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableHeaderView.makeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard tableHeaderView.isFirstTextValid,
            let sessionName = tableHeaderView.firstText else {
            view.endEditing(true)
            return
        }

        // Calls text field and text view didEndEditing() to save data
        view.endEditing(true)
        customDataSource?.saveSession(name: sessionName, info: tableHeaderView.secondText)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Used for resizing the tableView.headerView when the info text view becomes large enough
        if !didLayoutTableHeaderView {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.tableHeaderView?.layoutIfNeeded()
                self.tableView.tableHeaderView = self.tableView.tableHeaderView
            }
        }
        didLayoutTableHeaderView = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupColors()
    }
}

// MARK: - ViewAdding
extension CreateEditSessionTVC: ViewAdding {
    func setupNavigationBar() {
        title = customDataSource?.sessionState.rawValue ?? ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addExerciseButtonTapped))

        // This allows there to be a smooth transition from large title to small and vice-versa
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
    }

    func setupViews() {
        tableView.dataSource = customDataSource
        tableView.delegate = customDelegate

        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.keyboardDismissMode = .interactive
        tableView.register(ExerciseHeaderTVCell.self,
                           forCellReuseIdentifier: ExerciseHeaderTVCell.reuseIdentifier)
        tableView.register(ExerciseDetailTVCell.self,
                           forCellReuseIdentifier: ExerciseDetailTVCell.reuseIdentifier)
        tableView.register(ButtonTVCell.self,
                           forCellReuseIdentifier: ButtonTVCell.reuseIdentifier)

        if mainTBC?.isSessionInProgress ?? false {
            tableView.contentInset.bottom = minimizedHeight
        }

        let session = customDataSource?.session
        var dataModel = SessionHeaderViewModel()
        dataModel.firstText = session?.name ?? Constants.namePlaceholderText
        dataModel.secondText = session?.info ?? Constants.infoPlaceholderText
        dataModel.textColor = customDataSource?.sessionState == .create ?
                             .dimmedDarkGray : .dynamicBlack

        tableHeaderView.configure(dataModel: dataModel)
        tableHeaderView.isContentEditable = true
        tableHeaderView.customTextViewDelegate = self
    }

    func setupColors() {
        view.backgroundColor = .dynamicWhite
    }

    func addConstraints() {
        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        NSLayoutConstraint.activate([
            tableHeaderView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        ])
    }
}

// MARK: - Funcs
extension CreateEditSessionTVC {
    @objc private func addExerciseButtonTapped(_ sender: Any) {
        Haptic.sendSelectionFeedback()
        view.endEditing(true)

        let exercisesTVC = VCFactory.makeExercisesTVC(style: .grouped,
                                                      presentationStyle: .modal,
                                                      exerciseUpdatingDelegate: self,
                                                      exercisesTVDS: exercisesTVDS)

        let modalNC = VCFactory.makeMainNC(rootVC: exercisesTVC,
                                           transitioningDelegate: self)
        navigationController?.present(modalNC, animated: true)
    }
}
