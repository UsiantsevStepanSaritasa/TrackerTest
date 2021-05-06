//
//  BluetoothViewController.swift
//  TrackerTest
//
//  Created by Stepan on 26.04.2021.
//

import UIKit
import CoreBluetooth
import UserNotifications

class BluetoothViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    private struct Peripheral {
        let peripheral: CBPeripheral
        let rssi: NSNumber
        let date: Date
    }
    
    private struct LastPeripheralNotification: Equatable {
        let id: UUID
        var date: Date
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    let centralManager: CBCentralManager = CBCentralManager()
    let peripheralManager: CBPeripheralManager = CBPeripheralManager()
    let uuid: CBUUID = CBUUID(string: "12E61727-B41A-436F-B64D-4777B35F2294")

    private var timer: Timer?
    private var peripherals: [Peripheral] = []
    private var lastNotifications: [LastPeripheralNotification] = []
    private var characteristic: CBMutableCharacteristic?
    private var subscribedCentrals = [CBCharacteristic:[CBCentral]]()
    private var advertisingMessage: String?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        print("Class INITed at: \(Date().timeIntervalSince1970)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in }

        view.addSubview(tableView)
        
        title = "Bluetooth Tracker"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAdvertisingAlert))
        
        startAdvertisingIfPossible()
        print("STATE central: ", centralManager.state.rawValue)
        print("STATE peripheral: ", peripheralManager.state.rawValue)
        centralManager.delegate = self
        peripheralManager.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification(_:)),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    private func startScanIfPossible() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [uuid], options: nil)
        }
    }

    @objc private func showAdvertisingAlert() {
        let alertController = UIAlertController(title: "Enter advertising message", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        
        let submitAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self, let textField = alertController.textFields?[0] else { return }
            
            self.advertisingMessage = textField.text
            
            self.peripheralManager.stopAdvertising()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func didBecomeActiveNotification(_ notification: Notification) {
        startTimer()
    }

    @objc private func didEnterBackgroundNotification(_ notification: Notification) {
        stopTimer()
        startScanIfPossible()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(tick(_:)), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startAdvertisingIfPossible() {
        guard peripheralManager.state == .poweredOn, !peripheralManager.isAdvertising else {
            return
        }

        guard let message = advertisingMessage else {
            peripheralManager.startAdvertising(nil)
            
            return
        }
        
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : message])
    }

    @objc private func tick(_ sender: Timer) {
        startScanIfPossible()
        startAdvertisingIfPossible()
        removeStalePeripherals()
    }

    private func updatePeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        if let i = peripherals.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            peripherals[i] = Peripheral(peripheral: peripheral, rssi: rssi, date: Date())
        } else {
            peripherals.append(Peripheral(peripheral: peripheral, rssi: rssi, date: Date()))
        }
        peripherals.sort(by: { $0.rssi.intValue > $1.rssi.intValue })
        tableView.reloadData()
    }

    private func removeStalePeripherals() {
        let date = Date()
        peripherals = peripherals.filter({ date.timeIntervalSince($0.date) < 3.0 })
        tableView.reloadData()
    }

    private func showNotificationIfNeeded(peripheral: CBPeripheral) {
        if
            let lastNotification = lastNotifications.filter({ $0.id == peripheral.identifier }).first,
            lastNotification.date.timeIntervalSince1970 < (Date().timeIntervalSince1970 - 300),
            UIApplication.shared.applicationState == .background
        {
            print("Entered UPDATE existing notification")
            setupNotification(peripheral: peripheral)
            lastNotifications.removeAll { notification in
                notification.id == peripheral.identifier
            }
            lastNotifications.append(LastPeripheralNotification(id: peripheral.identifier, date: Date()))
            
        } else if
            !lastNotifications.contains(where: { lastNotification in
                lastNotification.id == peripheral.identifier                
            }),
            UIApplication.shared.applicationState == .background
        {
            setupNotification(peripheral: peripheral)
            lastNotifications.append(LastPeripheralNotification(id: peripheral.identifier, date: Date()))
            print("Entered CREATE new notification")
        }
    }
    
    private func setupNotification(peripheral: CBPeripheral) {
        let content = UNMutableNotificationContent()
        content.title = "New Device Found"
        content.body = peripheral.name ?? "<unknown>"
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: nil)
        
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        print("Notification has been sent")
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Failed to add notification \(error)")
            }
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        let p = peripherals[indexPath.row]
        cell?.textLabel?.text = "\(p.peripheral.name ?? "<unknown>"), \(p.rssi)dBm"
        return cell!
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [uuid], options: nil)

            let service = CBMutableService(type: uuid, primary: true)
            self.characteristic = CBMutableCharacteristic(type: CBUUID(string: "75324D43-7D9C-47C4-8F95-937453A3C298"), properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate], value: nil, permissions: [CBAttributePermissions.readable] )
            service.characteristics = [self.characteristic!]
            peripheralManager.add(service)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        updatePeripheral(peripheral, rssi: RSSI)
        showNotificationIfNeeded(peripheral: peripheral)
    }

    // MARK: - CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let service = CBMutableService(type: uuid, primary: true)
            peripheralManager.add(service)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        var centrals = self.subscribedCentrals[characteristic, default: [CBCentral]()]
        centrals.append(central)
        self.subscribedCentrals[characteristic] = centrals
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        // pass any data
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [uuid]])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("ERROR BLUETOOTH: ", error)
        }
    }
    
    deinit {
        print("Class has DEINITed at: \(Date().timeIntervalSince1970)")
    }
}

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension Data {
    
    var uint16: UInt16 {
        get {
            let i16array = self.withUnsafeBytes { $0.load(as: UInt16.self) }
            return i16array
        }
    }
}
