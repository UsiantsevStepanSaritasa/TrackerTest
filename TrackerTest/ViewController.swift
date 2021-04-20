//
//  ViewController.swift
//  TrackerTest
//
//  Created by Stepan on 16.04.2021.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    private let tableView = UITableView()
    private let locationManager = LocationManager()
    
    var array = [
        "latitude: 35,513531531531,\n longitude: 35,9510395019305130,\n TIME: \(Date())",
        "latitude: 85,5135t1531,\n longitude: 54,9510395019305130,\n TIME: 13049310:13041309:1349013",
        "latitude: 05,513531531531,\n longitude: 83,9510395019305130,\n TIME: 13049310:13041309:1349013",
        "latitude: 45,513531531531,\n longitude: 36,9510395019305130,\n TIME: 13049310:13041309:1349013"
    ]
    
//    var resultArray = [String]()
    var resultArray = [TrackData]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
//        UserDefaults.standard.synchronize()
        
        locationManager.locationDelegate = self
//        locationManager.notificationDelegate = self
//        UNUserNotificationCenter.current().delegate = self
        
        // for notification when user is near specific location
//        let notificationInfo = LocationNotificationInfo(
//            notificationId: "nyc_promenade_notification_id",
//            locationId: "nyc_promenade_location_id",
//            radius: 500,
//            latitude: 56.819981,
//            longitude: 60.628826,
//            title: "Welcome to the Brooklyn Promenade!",
//            body: "Tap to see more info",
//            data: ["location": "NYC Brooklyn Promenade"]
//        )
//        
//        locationManager.requestNotification(with: notificationInfo)
        
        addMessage()
        
        title = "TrackerTest"
        view.backgroundColor = .white
        setupUI()
    }
    
    func addMessage() {
        var existingArray = [TrackData]()
        if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
            guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
            existingArray = array
        }

        let updatedLocation = UserDefaults.standard.string(forKey: "NewLocation") ?? ""
        let launchMessage = UserDefaults.standard.string(forKey: "LaunchMessage") ?? ""
        
        let latitude = UserDefaults.standard.double(forKey: "CurrentLatitude")
        let longitude = UserDefaults.standard.double(forKey: "CurrentLongitude")
        
        let newData = TrackData(description: updatedLocation, latitude: latitude, longitude: longitude)
        let launchData = TrackData(description: launchMessage, latitude: 0, longitude: 0)
//        let terminateData = TrackData(description: terminateMessage, latitude: 0, longitude: 0)
        
        
        if !existingArray.contains(newData) {
            existingArray.append(newData)
        }
        if !existingArray.contains(launchData) {
            existingArray.append(launchData)
        }
        
        if let data = try? JSONEncoder().encode(existingArray) {
            UserDefaults.standard.set(data, forKey: "TrackedData")
        }
        
        if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
            guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
            resultArray = array
        }
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resultArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CellId")
        
        cell.textLabel?.text = resultArray[indexPath.row].description
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let latitude: CLLocationDegrees = resultArray[indexPath.row].latitude
        let longitude: CLLocationDegrees = resultArray[indexPath.row].longitude
        let regionDistance: CLLocationDistance = 1000
        
        print(latitude, longitude)
        
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "PLACEMARK"
        
        MKMapItem.openMaps(with: [mapItem], launchOptions: [MKLaunchOptionsMapCenterKey: MKCoordinateSpan()])
    }
}

extension ViewController: LocationManagerDelegate {
    func updateLocationValue() {
        var existingArray = [TrackData]()
        if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
            guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
            existingArray = array
        }
        
        let updatedLocation = UserDefaults.standard.string(forKey: "NewLocation") ?? ""
        let launchMessage = UserDefaults.standard.string(forKey: "LaunchMessage") ?? ""
        let terminateMessage = UserDefaults.standard.string(forKey: "TerminateMessage") ?? ""
        
        let latitude = UserDefaults.standard.double(forKey: "CurrentLatitude")
        let longitude = UserDefaults.standard.double(forKey: "CurrentLongitude")
        
        let newData = TrackData(description: updatedLocation, latitude: latitude, longitude: longitude)
        let launchData = TrackData(description: launchMessage, latitude: 0, longitude: 0)
        let terminateData = TrackData(description: terminateMessage, latitude: 0, longitude: 0)
        
        
        if !existingArray.contains(newData) {
            existingArray.append(newData)
        }
        if !existingArray.contains(launchData) {
            existingArray.append(launchData)
        }
        if !existingArray.contains(terminateData) {
            existingArray.append(terminateData)
        }
        
        if let data = try? JSONEncoder().encode(existingArray) {
            UserDefaults.standard.set(data, forKey: "TrackedData")
        }
        
        if let existingData = UserDefaults.standard.data(forKey: "TrackedData") {
            guard let array = try? JSONDecoder().decode([TrackData].self, from: existingData) else { return }
            resultArray = array
        }
        tableView.reloadData()
    }
}

//extension ViewController: LocationNotificationSchedulerDelegate {
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        if response.notification.request.identifier == "nyc_promenade_notification_id" {
//            let notificationData = response.notification.request.content.userInfo
//            let message = "You have reached \(notificationData["location"] ?? "your location!")"
//            
//            let alertController = UIAlertController(title: "Welcome!",
//                                                    message: message,
//                                                    preferredStyle: .alert)
//            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            present(alertController, animated: true)
//        }
//        completionHandler()
//    }
//}

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "nyc_promenade_notification_id" {
            let notificationData = response.notification.request.content.userInfo
            let message = "You have reached \(notificationData["location"] ?? "your location!")"
            
            let alertController = UIAlertController(title: "Welcome!",
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
        }
        completionHandler()
    }
}

struct TrackData: Codable, Equatable {
    let description: String
    let latitude: Double
    let longitude: Double
}
