//
//  Helpers.swift
//  TrackerTest
//
//  Created by Stepan on 20.04.2021.
//

import Foundation

public func dateFormat(with date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = .current
    dateFormatter.dateFormat = "d MMM' at 'HH:mm:ss"
    return dateFormatter.string(from: date)
}
