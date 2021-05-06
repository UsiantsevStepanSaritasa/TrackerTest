//
//  FirebaseManager.swift
//  TrackerTest
//
//  Created by Stepan on 20.04.2021.
//

import Foundation
import FirebaseFirestore

//locationsForSimulator
//locationsForPhysical
//locationsForPresentation

class FirebaseManager {
    private let db = Firestore.firestore()
    
    static let shared = FirebaseManager()
    
    func sendNewLocationToFirestore(location: String, latitude: Double, longitude: Double, time: Date, completion: @escaping (Result<(), Error>) -> Void) {
        let locationData: [String: Any] = [
            "description": location,
            "date": "\(dateFormat(with: time))",
            "latitude": latitude,
            "longitude": longitude
        ]
        
        db.collection("locationsForPresentation").document("locations").updateData([
            "location for \(dateFormat(with: time))": locationData
        ]) { (error: Error?) in
            if let error = error {
//                print("failed sendingNewLocation ERROR: ", error.localizedDescription)
                completion(.failure(error))
            } else {
//                print("Successfully sent!")
                completion(.success(()))
            }
        }
    }
    
    func fetchData(completion: @escaping (Result<[LocationData], Error>) -> Void) {
        var fetchedLocations = [LocationData]()
        
        let docRef = db.collection("locationsForPresentation").document("locations")
        
        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let document = document, document.exists {
                let decoder = JSONDecoder()
                
                guard let dict = document.data() else { return }
                for (_, value) in dict {
                    if let data = try? JSONSerialization.data(withJSONObject: value, options: []) {
                        guard let location = try? decoder.decode(LocationData.self, from: data) else {
                            return completion(.failure(CustomError.messageError(description: "Decode error while fetch doc from Firestore")))
                        }
                        fetchedLocations.append(location)
                    }
                }
                completion(.success(self.sortLocations(for: fetchedLocations)))
            } else {
//                print(CustomError.messageError(description: "Document doesn't exist in Firestore"))
                completion(.failure(CustomError.messageError(description: "Document doesn't exist in Firestore")))
            }
        }
    }
    
    private func sortLocations(for fetchedLocations: [LocationData]) -> [LocationData] {
        fetchedLocations.sorted { rawDate(from: $0.date) < rawDate(from: $1.date) }
    }
    
    private func rawDate(from formattedDate: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM' at 'HH:mm:ss"
        
        guard let date = dateFormatter.date(from: formattedDate) else { return Date() }
        return date
    }
}
