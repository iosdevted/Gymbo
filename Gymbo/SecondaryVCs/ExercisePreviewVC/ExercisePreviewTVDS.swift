//
//  ExercisePreviewTVDS.swift
//  Gymbo
//
//  Created by Rohan Sharma on 12/29/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import UIKit

// MARK: - Properties
class ExercisePreviewTVDS: NSObject {
    var exercise = Exercise()

    private let sections = Section.allCases
    private let items: [[Item]] = [
        [.title],
        [.images],
        [.instructions],
        [.tips]
    ]
}

// MARK: - Structs/Enums
extension ExercisePreviewTVDS {
    private enum Constants {
        static let noImagesText = "No images"
        static let noInstructionsText = "No instructions"
        static let noTipsText = "No tips"
    }

    enum Section: String, CaseIterable {
        case name = "Name"
        case images = "Images"
        case instructions = "Instructions"
        case tips = "Tips"
    }

    enum Item: String {
        case images
        case instructions
        case tips
        case title
    }
}

// MARK: - Funcs
extension ExercisePreviewTVDS {
    private func getTwoLabelsTVCell(in tableView: UITableView,
                                    for indexPath: IndexPath) -> TwoLabelsTVCell {
        guard let twoLabelsTVCell = tableView.dequeueReusableCell(
                withIdentifier: TwoLabelsTVCell.reuseIdentifier,
                for: indexPath) as? TwoLabelsTVCell else {
            fatalError("Could not dequeue \(TwoLabelsTVCell.reuseIdentifier)")
        }

        twoLabelsTVCell.configure(topText: exercise.name ?? "", bottomText: exercise.groups ?? "")
        return twoLabelsTVCell
    }

    private func getLabelCell(in tableView: UITableView,
                              for indexPath: IndexPath,
                              text: String,
                              font: UIFont = .normal) -> LabelTVCell {
        guard let labelTVCell = tableView.dequeueReusableCell(
                withIdentifier: LabelTVCell.reuseIdentifier,
                for: indexPath) as? LabelTVCell else {
            fatalError("Could not dequeue \(LabelTVCell.reuseIdentifier)")
        }

        labelTVCell.configure(text: text, font: font)
        return labelTVCell
    }

    private func getSwipableImageViewCell(in tableView: UITableView,
                                          for indexPath: IndexPath) -> SwipableImageVTVCell {
        guard let swipableImageVTVCell = tableView.dequeueReusableCell(
            withIdentifier: SwipableImageVTVCell.reuseIdentifier,
            for: indexPath) as? SwipableImageVTVCell else {
            fatalError("Could not dequeue \(SwipableImageVTVCell.reuseIdentifier)")
        }

        let imageFileNames = Array(exercise.imageNames)
        swipableImageVTVCell.configure(imageFileNames: imageFileNames,
                                       isUserMade: exercise.isUserMade)
        return swipableImageVTVCell
    }

    func indexOf(item: Item) -> Int? {
        var index: Int?
        items.forEach {
            if $0.contains(item) {
                index = $0.firstIndex(of: item)
                return
            }
        }
        return index
    }
}

// MARK: - UITableViewDataSource
extension ExercisePreviewTVDS: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        items[section].count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let item = items[indexPath.section][indexPath.row]

        switch item {
        case .title:
            cell = getTwoLabelsTVCell(in: tableView, for: indexPath)
        case .images:
            if exercise.imageNames.isEmpty {
                cell = getLabelCell(in: tableView, for: indexPath, text: Constants.noImagesText)
            } else {
                cell = getSwipableImageViewCell(in: tableView, for: indexPath)
            }
        case .instructions, .tips:
            let text = item == .instructions ? exercise.instructions : exercise.tips
            let emptyText = item == .instructions ? Constants.noInstructionsText : Constants.noTipsText
            cell = getLabelCell(in: tableView,
                                for: indexPath,
                                text: text ?? emptyText)
        }
        Utility.configureCellRounding(in: tableView,
                                      with: cell,
                                      for: indexPath)
        return cell
    }
}
