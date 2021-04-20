//
//  LocationManager.swift
//  TrackerTest
//
//  Created by Stepan on 16.04.2021.
//

import Foundation
import CoreLocation
//import UserNotifications

protocol LocationManagerDelegate: class {
    func updateLocationValue()
}

//protocol LocationNotificationSchedulerDelegate: UNUserNotificationCenterDelegate {
//}

final class LocationManager: NSObject {
    static let geoCoder = CLGeocoder()
    
    private let locationManager = CLLocationManager()
    private var timer = Timer()
    private var currentLocation: CLLocation?
    private var updatedLocation: CLLocation?
    
    private let latitudeVisit = [Double]()
    
    lazy var exposedLocation: CLLocation? = locationManager.location
    
    weak var locationDelegate: LocationManagerDelegate?
//    weak var notificationDelegate: UNUserNotificationCenterDelegate? {
//        didSet {
//            UNUserNotificationCenter.current().delegate = notificationDelegate
//        }
//    }
//    weak var notificationDelegate: LocationNotificationSchedulerDelegate? {
//        didSet {
//            UNUserNotificationCenter.current().delegate = notificationDelegate
//        }
//    }
    
    override init() {
        super.init()
        // timeInterval in seconds
//        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(saveUpdatedLocation), userInfo: nil, repeats: true)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringVisits()
        locationManager.startMonitoringSignificantLocationChanges()
        
//        requestNotification(notificationInfo: notificationInfo)
//        notificationDelegate = self
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        manager.stopUpdatingLocation()
//        requestNotification(notificationInfo: notificationInfo)
        guard let location = locations.last else {
            return UserDefaults.standard.set("No updated online location for \n TIME: \(Date())", forKey: "NewLocation")
        }
        let resultString = "\(location)".slice(from: "<", to: ">")
        let array = resultString?.components(separatedBy: ",")
        guard let unwrappedArray = array else { return }
        
        let latitude = UserDefaults.standard.double(forKey: "CurrentLatitude")
        let longitude = UserDefaults.standard.double(forKey: "CurrentLongitude")
        
        if Double(unwrappedArray[0]) == latitude, Double(unwrappedArray[1]) == longitude { return }
        
        UserDefaults.standard.set(Double(unwrappedArray[0]), forKey: "CurrentLatitude")
        UserDefaults.standard.set(Double(unwrappedArray[1]), forKey: "CurrentLongitude")
        
        UserDefaults.standard.set("Updating ONLINE: \(location) \n TIME: \(Date())", forKey: "NewLocation")
        locationDelegate?.updateLocationValue()
        print("Updating location: \(location)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            guard let location = manager.location else { return }
            print("auth - \(location)")
        case .denied, .restricted:
            print("non auth")
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            print("non determined")
        @unknown default:
            break
        }
    }
    
//    func requestNotification(with notificationInfo: LocationNotificationInfo) {
//        switch locationManager.authorizationStatus {
//        case .notDetermined:
//            locationManager.requestWhenInUseAuthorization()
//            askForNotificationPermissions(notificationInfo: notificationInfo)
//        case .authorizedWhenInUse, .authorizedAlways:
//            askForNotificationPermissions(notificationInfo: notificationInfo)
//        case .restricted, .denied:
//            print("Denied")
//            break
//        }
//    }
    
//    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
//        let clLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
//
//        print("VISIT location: \(clLocation)")
//
//        LocationManager.geoCoder.reverseGeocodeLocation(clLocation) { placemarks, _ in
//            if let place = placemarks?.first {
//                let description = "\(place)"
//                self.newVisitReceived(visit, description: description)
//            }
//        }
//    }
//
//    func newVisitReceived(_ visit: CLVisit, description: String) {
////        let location = Location(visit: visit, descriptionString: description)
//    }
}

//extension LocationManager {
//    func askForNotificationPermissions(notificationInfo: LocationNotificationInfo) {
//        guard CLLocationManager.locationServicesEnabled() else {
//            return
//        }
//        UNUserNotificationCenter.current().requestAuthorization(
//            options: [.alert, .sound, .badge],
//            completionHandler: { [weak self] granted, _ in
//                guard granted else {
//                    DispatchQueue.main.async {
//                        print("User denied notification access")
//                    }
//                    return
//                }
//                self?.scheduleNotification(notificationInfo: notificationInfo)
//        })
//    }
//
//    func notificationContent(notificationInfo: LocationNotificationInfo) -> UNMutableNotificationContent {
//        let notification = UNMutableNotificationContent()
//        notification.title = notificationInfo.title
//        notification.body = notificationInfo.body
//        notification.sound = UNNotificationSound.default
//
//        if let data = notificationInfo.data {
//            notification.userInfo = data
//        }
//        return notification
//    }
//
//    func destinationRegion(notificationInfo: LocationNotificationInfo) -> CLCircularRegion {
//        let destRegion = CLCircularRegion(center: notificationInfo.coordinates,
//                                          radius: notificationInfo.radius,
//                                          identifier: notificationInfo.locationId)
//        destRegion.notifyOnEntry = true
//        destRegion.notifyOnExit = false
//        return destRegion
//    }
//
//    func scheduleNotification(notificationInfo: LocationNotificationInfo) {
//        let notification = notificationContent(notificationInfo: notificationInfo)
//        let destRegion = destinationRegion(notificationInfo: notificationInfo)
//        let trigger = UNLocationNotificationTrigger(region: destRegion, repeats: false)
//        let request = UNNotificationRequest(
//            identifier: notificationInfo.notificationId,
//            content: notification,
//            trigger: trigger
//        )
//
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        UNUserNotificationCenter.current().add(request) { [weak self] error in
//            DispatchQueue.main.async {
//                print("Location notification is completed: \(error?.localizedDescription)")
//            }
//        }
//    }
//}

extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

//struct Location {
//    let latitude: Double
//    let longitude: Double
//    let date: Date
//    let dateString: String
//    let description: String
//
//    init(visit: CLVisit, descriptionString: String) {
//        latitude = visit.coordinate.latitude
//        longitude = visit.coordinate.longitude
//        date = visit.arrivalDate
//        dateString = "\(visit.arrivalDate)"
//        description = descriptionString
//    }
//}
//struct LocationNotificationInfo {
//    // Identifiers
//    let notificationId: String
//    let locationId: String
//    
//    // Location
//    let radius: Double
//    let latitude: Double
//    let longitude: Double
//    
//    // Notification
//    let title: String
//    let body: String
//    let data: [String: Any]?
//    
//    /// CLLocation Coordinates
//    var coordinates: CLLocationCoordinate2D {
//        return CLLocationCoordinate2D(latitude: latitude,
//                                      longitude: longitude)
//    }
//}
//
//extension LocationManager: LocationNotificationSchedulerDelegate {
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("NOTIFICATION RECEIVED")
//    }
//}
