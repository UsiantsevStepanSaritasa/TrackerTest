//
//  FirebaseManager.swift
//  TrackerTest
//
//  Created by Stepan on 20.04.2021.
//

import Foundation
import FirebaseFirestore

class FirebaseManager {
    private let db = Firestore.firestore()
    
    static let shared = FirebaseManager()
    
    func sendNewLocationToFirestore(location: String) {
        db.collection("locationsForSimulator").document("locations").updateData([
            "location for \(dateFormat(with: Date()))": FieldValue.arrayUnion([
                location,
                dateFormat(with: Date())
            ])
        ]) { (error: Error?) in
            if let error = error {
                print("ERROR FIRESTORE: ", error.localizedDescription)
            } else {
                print("Successfully sent!")
            }
        }
    }
}
