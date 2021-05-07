//
//  HKStoreHelper.swift
//  HealthTestApp
//
//  Created by Denis Kovalev on 19.04.2021.
//

import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailableOnDevice
    case dataTypeNotAvailable
    case permissionError
    case noSamplesFound(HKSampleType)

    var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice: return "HealthKit is not available"
        case .dataTypeNotAvailable: return "Data type is not available"
        case .permissionError: return "Permission error"
        case let .noSamplesFound(type): return "No samples found for type: \(type)"
        }
    }
}

class HKStoreHelper {

    static let store = HKHealthStore()

    /// Called, when the error occured
    var onError: ((Error) -> Void)?
    /// Called, when authorization was completed successfully
    var onHealthKitAuthorized: (() -> Void)?

    /// Requests authorization for defined types of HealthKit entities
    func authorizeHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            onError?(HealthKitError.notAvailableOnDevice)
            return
        }

        // Characteristics
        guard let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
              let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
              let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            onError?(HealthKitError.dataTypeNotAvailable)
            return
        }

        // Quantities
        guard let energyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            onError?(HealthKitError.dataTypeNotAvailable)
            return
        }

        // Categories
        guard let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            onError?(HealthKitError.dataTypeNotAvailable)
            return
        }

        // Types requested to write
        let typesToWrite: Set<HKSampleType> = [energyBurned]
        // Types requested to read
        let typesToRead: Set<HKObjectType> = [dateOfBirth, bloodType, biologicalSex, energyBurned, mindfulSession]

        // Make a request
        HKStoreHelper.store.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            // Authorization request is always async, so, perform result on main thread
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.onError?(error)
                    return
                }
                self?.onHealthKitAuthorized?()
            }
        }
    }

    /// Gets static characteristics (age, sex and blood type) from HealthKit profile
    func getCharacteristics() -> (age: Int, biologicalSex: HKBiologicalSex, bloodType: HKBloodType)? {
        let healthKitStore = HKStoreHelper.store
        do {
            let birthdayComponents = try healthKitStore.dateOfBirthComponents()
            let biologicalSex = try healthKitStore.biologicalSex()
            let bloodType = try healthKitStore.bloodType()

            // Calculate age
            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year], from: today)
            let thisYear = todayDateComponents.year!
            let age = thisYear - birthdayComponents.year!

            // Unwrap sex and blood type
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            let unwrappedBloodType = bloodType.bloodType

            return (age, unwrappedBiologicalSex, unwrappedBloodType)
        } catch {
            onError?(HealthKitError.permissionError)
            return nil
        }
    }

    /// Asynchronously gets the most recent sample for ```sampleType```.
    func getMostRecentSample(for sampleType: HKSampleType,
                             success: @escaping (HKSample) -> Void) {

        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 1

        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            // Request is async operation, so perform result on main thread
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.onError?(error)
                    return
                }
                guard let samples = samples, let mostRecentSample = samples.first else {
                    self?.onError?(HealthKitError.noSamplesFound(sampleType))
                    return
                }

                success(mostRecentSample)
            }
        }
        // Perform request asynchronously
        HKStoreHelper.store.execute(sampleQuery)
    }

    /// Saves new active energy value by date in HealthKit store
    func saveActiveEnergyBurned(count: Double, date: Date, success: @escaping (() -> Void)) {

        guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            onError?(HealthKitError.dataTypeNotAvailable)
            return
        }

        // Save data in kilocalories
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: count)
        // Create sample to save data
        let energyBurnedSample = HKQuantitySample(type: energyBurnedType, quantity: quantity, start: date, end: date)

        // Perform save request
        HKHealthStore().save(energyBurnedSample) { (isSuccess, error) in
            // Saving is async operation, so perform result on main thread
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.onError?(error)
                } else {
                    success()
                }
            }
        }
    }
}
