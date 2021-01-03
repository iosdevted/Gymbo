//
//  AllSessionsDetailTVC.swift
//  Gymbo
//
//  Created by Rohan Sharma on 1/2/21.
//  Copyright © 2021 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Properties
class AllSessionsDetailTVC: UITableViewController {
    private let tableHeaderView = SessionDetailHV()
    private var didLayoutTableHeaderView = false

    var customDataSource: AllSessionsDetailTVDS?
    var customDelegate: AllSessionsDetailTVD?
}

// MARK: - Structs/Enums
private extension AllSessionsDetailTVC {
    struct Constants {
    }
}

// MARK: - UIViewController Var/Funcs
extension AllSessionsDetailTVC {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        addViews()
        setupViews()
        setupColors()
        addConstraints()
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
            didLayoutTableHeaderView = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupColors()
    }
}

// MARK: - ViewAdding
extension AllSessionsDetailTVC: ViewAdding {
    func setupNavigationBar() {
        title = "Session Details"
    }

    func addViews() {
    }

    func setupViews() {
        tableView.dataSource = customDataSource
        tableView.delegate = customDelegate

        tableView.allowsSelection = false
        tableView.sectionFooterHeight = 0
        tableView.tableFooterView = UIView()
        tableView.register(ExercisesHFV.self,
                           forHeaderFooterViewReuseIdentifier: ExercisesHFV.reuseIdentifier)
        tableView.register(LabelTVCell.self,
                           forCellReuseIdentifier: LabelTVCell.reuseIdentifier)

        let dataModel = customDataSource?.sessionHVDataModel() ?? SessionDetailHeaderModel()
        tableHeaderView.configure(dataModel: dataModel)
    }

    func setupColors() {
        [view, tableView].forEach { $0.backgroundColor = .dynamicWhite }
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
extension AllSessionsDetailTVC {
}

// MARK: ListDataSource
extension AllSessionsDetailTVC: ListDataSource {
}

// MARK: - ListDelegate
extension AllSessionsDetailTVC: ListDelegate {
}
