//
//  DataFetchDelegate.swift
//  Gymbo
//
//  Created by Rohan Sharma on 6/20/20.
//  Copyright © 2020 Rohan Sharma. All rights reserved.
//

protocol DataFetchDelegate: class {
    func didBeginFetch()
    func didEndFetch()
}

extension DataFetchDelegate {
    func didBeginFetch() {}
    func didEndFetch() {}
}
