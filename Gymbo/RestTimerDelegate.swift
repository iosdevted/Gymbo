//
//  RestTimerDelegate.swift
//  Gymbo
//
//  Created by Rohan Sharma on 6/20/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

protocol RestTimerDelegate: class {
    func started(totalTime: Int)
    func timeUpdated(totalTime: Int, timeRemaining: Int)
    func ended()
}
