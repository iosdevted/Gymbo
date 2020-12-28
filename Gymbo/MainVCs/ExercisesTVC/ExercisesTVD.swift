//
//  ExercisesTVD.swift
//  Gymbo
//
//  Created by Rohan Sharma on 12/26/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import RealmSwift

// MARK: - Properties
class ExercisesTVD: NSObject {
    var presentationStyle = PresentationStyle.normal
    var selectedExerciseNames = [String]()

    private var sectionTitles: [String] {
        Array(realm?.objects(ExercisesList.self).first?.sectionTitles ?? List<String>())
    }

    private var realm: Realm? {
        try? Realm()
    }

    private weak var listDelegate: ListDelegate?

    init(listDelegate: ListDelegate?) {
        self.listDelegate = listDelegate
    }
}

// MARK: - Structs/Enums
extension ExercisesTVD {
    private struct Constants {
        static let headerHeight = CGFloat(40)
        static let exerciseCellHeight = CGFloat(70)
    }
}

// MARK: - Funcs
extension ExercisesTVD {
    private func titleForHeaderIn(section: Int) -> String {
        sectionTitles[section]
    }
}

// MARK: - UITableViewDelegate
extension ExercisesTVD: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        tableView.numberOfSections == 1 ? 0 : Constants.headerHeight
    }

    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        tableView.numberOfSections == 1 ? 0 : Constants.headerHeight
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ExercisesHeaderFooterView.reuseIdentifier) as? ExercisesHeaderFooterView else {
            return nil
        }

        let title = titleForHeaderIn(section: section)
        headerView.configure(title: title)
        return headerView
    }

    func tableView(_ tableView: UITableView,
                   estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.exerciseCellHeight
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.exerciseCellHeight
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        guard presentationStyle == .modal,
              let exerciseCell = tableView
                .cellForRow(at: indexPath) as? ExerciseTVCell,
              let exerciseName = exerciseCell.exerciseName else {
            listDelegate?.didSelectItem(at: indexPath)
            return
        }
        Haptic.sendSelectionFeedback()

        if !selectedExerciseNames.contains(exerciseName) {
            selectedExerciseNames.append(exerciseName)
        }
    }

    func tableView(_ tableView: UITableView,
                   didDeselectRowAt indexPath: IndexPath) {
        guard presentationStyle != .normal,
              let exerciseCell = tableView
                .cellForRow(at: indexPath) as? ExerciseTVCell,
              let exerciseName = exerciseCell.exerciseName else {
            return
        }
        Haptic.sendSelectionFeedback()

        if let index = selectedExerciseNames.firstIndex(where: { (name) -> Bool in
            return name == exerciseName
        }) {
            selectedExerciseNames.remove(at: index)
        }
        listDelegate?.didDeselectItem(at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
        guard tableView.cellForRow(at: indexPath) is ExerciseTVCell else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Delete") { [weak self] _, _, completion in
            Haptic.sendImpactFeedback(.medium)

            self?.listDelegate?
                .tableView(tableView, trailingSwipeActionsConfiguration: indexPath)
            if tableView.numberOfRows(inSection: indexPath.section) > 1 {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                tableView.deleteSections([indexPath.section], with: .automatic)
            }
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
}
