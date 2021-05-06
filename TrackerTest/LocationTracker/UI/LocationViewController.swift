//
//  LocationViewController.swift
//  TrackerTest
//
//  Created by Stepan on 16.04.2021.
//

import UIKit
import CoreLocation
import MapKit

class LocationViewController: UIViewController {
    private let tableView = UITableView()
    
    var fetchedLocations = [LocationData]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationManager.shared.locationDelegate = self
        fetchData()
        
        title = "TrackerTest"
        view.backgroundColor = .white
        setupUI()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        fetchData()
//    }
    
    func fetchData() {
        FirebaseManager.shared.fetchData { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(data):
//                self.newLocations(with: data)
                self.fetchedLocations = data
                self.tableView.reloadData()
            case let .failure(error):
//                print("fetchData from Firebase ERROR: ", error)
                self.showError(error)
            }
        }
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
    
//    private func newLocations(with data: [LocationData]) {
//        for loc in data {
//            guard
//                let lastDate = fetchedLocations.last?.date,
//                let lastDescription = fetchedLocations.last?.description
//            else {
//                fetchedLocations.append(loc)
//                continue
//            }
//            if loc.description != lastDescription {
//                fetchedLocations.append(loc)
//            }
//        }
//    }
}

extension LocationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedLocations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CellId")
        
        let description = fetchedLocations[indexPath.row].description + "\n TIME: \(fetchedLocations[indexPath.row].date)"
        
        cell.textLabel?.text = description
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let latitude: CLLocationDegrees = fetchedLocations[indexPath.row].latitude
        let longitude: CLLocationDegrees = fetchedLocations[indexPath.row].longitude
//        let regionDistance: CLLocationDistance = 1000
        
//        print(latitude, longitude)
        
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "PLACEMARK"
        
        MKMapItem.openMaps(with: [mapItem], launchOptions: [MKLaunchOptionsMapCenterKey: MKCoordinateSpan()])
    }
}

extension LocationViewController: UNUserNotificationCenterDelegate {
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

extension LocationViewController: LocationManagerDelegate {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager) {
        self.fetchData()
    }
    
    func locationManager(_ locationManager: LocationManager, didFailUpdatingLocationWith error: Error) {
        showError(error)
    }
}
