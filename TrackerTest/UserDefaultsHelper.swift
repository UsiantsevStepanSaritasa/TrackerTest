//
//  UserDefaultsHelper.swift
//  TrackerTest
//
//  Created by Stepan on 20.04.2021.
//

import Foundation

//public func saveNewLocation(for location: CLLocation) {
//    var existingArray = [TrackData]()
//    if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
//        guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
//        existingArray = array
//    }
//
//    let updatedLocation = UserDefaults.standard.string(forKey: "NewLocation") ?? ""
//    let launchMessage = UserDefaults.standard.string(forKey: "LaunchMessage") ?? ""
//
//    let latitude = UserDefaults.standard.double(forKey: "CurrentLatitude")
//    let longitude = UserDefaults.standard.double(forKey: "CurrentLongitude")
//
//    let newData = TrackData(description: updatedLocation, latitude: latitude, longitude: longitude)
//    let launchData = TrackData(description: launchMessage, latitude: 0, longitude: 0)
//    //        let terminateData = TrackData(description: terminateMessage, latitude: 0, longitude: 0)
//
//
//    if !existingArray.contains(newData) {
//        existingArray.append(newData)
//    }
//    if !existingArray.contains(launchData) {
//        existingArray.append(launchData)
//    }
//
//    if let data = try? JSONEncoder().encode(existingArray) {
//        UserDefaults.standard.set(data, forKey: "TrackedData")
//    }
//
//    if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
//        guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
//        resultArray = array
//    }
//    tableView.reloadData()
//}
