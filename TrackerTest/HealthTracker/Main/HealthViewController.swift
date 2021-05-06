//
//  ViewController.swift
//  HealthTestApp
//
//  Created by Denis Kovalev on 19.04.2021.
//

import UIKit
import HealthKit
import Combine

/// Main screen
class HealthViewController: UITableViewController {

    // MARK: - Properties

    /// Couples of title and string value for characteristics data
    var characreristics: [(String, String)] = [("Age", ""), ("Sex", ""), ("Blood Type", "")]

    /// Couples of title and string value for samples data
    var samples: [(String, String)] = [("Active Energy Burned", ""), ("Mindful Session", "")]

    /// Store helper instance
    let storeHelper = HKStoreHelper()

    // MARK: - UI Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureNavBar()
        bindHealthKitActions()
        storeHelper.authorizeHealthKit()
    }

    // MARK: - UI Methods

    private func configureUI() {
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.sectionHeaderHeight = 40.0
        view.backgroundColor = .white
    }

    private func configureNavBar() {
        navigationItem.title = "Health Data"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Update", style: .plain, target: self, action: #selector(updateAction)),
            UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addAction))
        ]
    }

    /// Binds actions from Health Kit helper
    private func bindHealthKitActions() {
        storeHelper.onError = { [weak self] error in
            guard let self = self else { return }
            AlertPresenter.presentErrorAlert(message: error.localizedDescription, target: self)
        }

        storeHelper.onHealthKitAuthorized = { [weak self] in
            self?.updateCharacteristics()
            self?.updateSamples()
        }
    }

    /// Updates characteristic rows
    private func updateCharacteristics() {
        guard let (age, sex, bloodType) = storeHelper.getCharacteristics() else {
            return
        }

        characreristics[0].1 = String(age)
        characreristics[1].1 = sex.stringRepresentation
        characreristics[2].1 = bloodType.stringRepresentation
        tableView.reloadData()
    }

    /// Updates sample rows
    private func updateSamples() {
        // Get types for necessary samples
        guard let energyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return
        }

        // Get recent energy burned sample from store
        storeHelper.getMostRecentSample(for: energyBurnedType) { [weak self] sample in
            guard let sample = sample as? HKQuantitySample else { return }
            // Convert it to Joules
            let joules =  sample.quantity.doubleValue(for: .joule())

            self?.samples[0].1 = String(format: "%.1lf J", joules)
            self?.tableView.reloadData()
        }

        // Get recent mindful session sample
        storeHelper.getMostRecentSample(for: mindfulSession) { [weak self] sample in
            // Convert interval to hours
            let interval = DateInterval(start: sample.startDate, end: sample.endDate).duration / 3600.0

            self?.samples[1].1 = String(format: "%.1lf hr", interval)
            self?.tableView.reloadData()
        }
    }

    /// Saves active energy burned value
    private func saveActiveEnergyBurned(count: Double) {
        storeHelper.saveActiveEnergyBurned(count: count, date: Date()) { [weak self] in
            self?.updateSamples()
        }
    }

    // MARK: - UI Callbacks

    @objc private func updateAction(_ sender: Any) {
        updateSamples()
        updateCharacteristics()
    }

    @objc private func addAction(_ sender: Any) {
        AlertPresenter.presentTextFieldAlert(title: "Add New Sample",
                                             message: "Add new energy burned sample",
                                             placeholder: "0 kcal",
                                             target: self) { [weak self] text in

            guard let count = Double(text) else { return }
            self?.saveActiveEnergyBurned(count: count)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension HealthViewController {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Characteristics" : "Samples"
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? characreristics.count : samples.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cellId")
        cell.textLabel?.text = indexPath.section == 0 ? characreristics[indexPath.row].0 : samples[indexPath.row].0
        cell.detailTextLabel?.text = indexPath.section == 0 ? characreristics[indexPath.row].1 : samples[indexPath.row].1
        return cell
    }
}

/// Makes label with text
private func makeLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .systemFont(ofSize: 15)
    label.textColor = .darkText
    label.text = text
    label.numberOfLines = 1
    return label
}
