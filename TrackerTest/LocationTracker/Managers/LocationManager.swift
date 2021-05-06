//
//  LocationManager.swift
//  TrackerTest
//
//  Created by Stepan on 16.04.2021.
//

import Foundation
import CoreLocation
import UIKit

protocol LocationManagerDelegate: class {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager)
    func locationManager(_ locationManager: LocationManager, didFailUpdatingLocationWith error: Error)
}

final class LocationManager: NSObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    
    private let latitudeVisit = [Double]()
    
    weak var locationDelegate: LocationManagerDelegate?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        // We might need it in the future if we'll want to track location more accurate in fore- and background.
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringVisits()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func startMonitoringSignificant() {
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Finish Location Update") { [weak self] in
            guard let self = self, let bcgTaskID = self.backgroundTaskID else { return }
            UIApplication.shared.endBackgroundTask(bcgTaskID)
            self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        guard let location = locations.last else { return }
        
        FirebaseManager.shared.sendNewLocationToFirestore(
            location: "Updating location: \(location)",
            latitude: Double(location.coordinate.latitude),
            longitude: Double(location.coordinate.longitude),
            time: location.timestamp
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
//                self.locationDelegate?.updateLocations()
                self.locationDelegate?.locationManagerDidUpdateLocation(self)
            case .failure(let error):
//                print("Failed sendNewLocation ERROR: ", error.localizedDescription)
                self.locationDelegate?.locationManager(self, didFailUpdatingLocationWith: error)
            }
            guard let bcgTaskID = self.backgroundTaskID else { return }
            UIApplication.shared.endBackgroundTask(bcgTaskID)
            self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
//        print("Updating location: \(location)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            guard manager.location != nil else { return }
        //            print("auth - \(location)")
        case .denied, .restricted:
//            print("non auth")
            self.locationDelegate?.locationManager(
                self,
                didFailUpdatingLocationWith: CustomError.messageError(description: "Please allow us to use your location data")
            )
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        //            print("non determined")
        @unknown default:
            break
        }
    }
}
