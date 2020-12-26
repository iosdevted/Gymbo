//
//  ExerciseDetails.swift
//  Gymbo
//
//  Created by Rohan Sharma on 6/14/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

import RealmSwift

// MARK: - Properties
@objcMembers class ExerciseDetails: Object {
    dynamic var last: String?
    dynamic var reps: String?
    dynamic var weight: String?

    convenience init(last: String? = nil, reps: String? = nil, weight: String? = nil) {
        self.init()

        self.last = last
        self.reps = reps
        self.weight = weight
    }
}
