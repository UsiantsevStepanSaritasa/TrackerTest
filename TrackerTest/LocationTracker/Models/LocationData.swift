//
//  LocationData.swift
//  TrackerTest
//
//  Created by Stepan on 23.04.2021.
//

import Foundation

struct LocationData: Codable, Equatable {
    let date: String
    let description: String
    let latitude: Double
    let longitude: Double
}
