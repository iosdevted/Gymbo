//
//  ListDataSource.swift
//  Gymbo
//
//  Created by Rohan Sharma on 12/27/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import UIKit

protocol ListDataSource: class {
    func reloadData()
    func dataStateChanged()
    func deleteCell(tvCell: UITableViewCell)
    func deleteCell(cvCell: UICollectionViewCell)
    func cellForRowAt(tvCell: UITableViewCell)
}

extension ListDataSource {
    func reloadData() {}
    func dataStateChanged() {}
    func deleteCell(tvCell: UITableViewCell) {}
    func deleteCell(cvCell: UICollectionViewCell) {}
    func cellForRowAt(tvCell: UITableViewCell) {}
}
