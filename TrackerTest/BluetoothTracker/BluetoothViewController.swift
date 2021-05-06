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
    private var characteristic: CBMutableCharacteristic?
    private var subscribedCentrals = [CBCharacteristic:[CBCentral]]()

    override func viewDidLoad() {
        super.viewDidLoad()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in

        }

        view.addSubview(tableView)

        startAdvertisingIfPossible()
//        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [uuid]])
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

    @objc private func didBecomeActiveNotification(_ notification: Notification) {
        startTimer()
    }

    @objc private func didEnterBackgroundNotification(_ notification: Notification) {
        stopTimer()
        startScanIfPossible()
//        startAdvertisingIfPossible()
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
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [uuid]])
    }

    @objc private func tick(_ sender: Timer) {
        startScanIfPossible()
//        startAdvertisingIfPossible()
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
        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "New Device Found"
            content.body = peripheral.name ?? "<unknown>"

            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString,
                        content: content, trigger: nil)

            // Schedule the request with the system.
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.add(request) { (error) in
               if let error = error {
                  print("Failed to add notification \(error)")
               }
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
    
//    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
//        if let error = error {
//            print("Error publishing channel: \(error.localizedDescription)")
//            return
//        }
//        print("Published channel \(PSM)")
//        
//        self.characteristic?.value = PSM.data
//        
//        self.peripheralManager.updateValue(PSM.data, for: self.characteristic!, onSubscribedCentrals: self.subscribedCentrals[self.characteristic!])
//    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        // pass any data
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [uuid]])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("ERROR BLUETOOTH: ", error)
        }
    }

//    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
//        if let characteristic = self.characteristic {
//            request.value = characteristic.value
//            self.peripheralManager.respond(to: request, withResult: .success)
//        } else {
//            self.peripheralManager.respond(to: request, withResult: .unlikelyError)
//        }
//    }
    
//    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
//        if let error = error {
//            print("Error opening channel: \(error.localizedDescription)")
//            return
//        }
//        if let channel = channel {
////            let connection = L2CapPeripheralConnection(channel: channel)
////            self.connectionHandler(connection)
//            print(channel)
//        }
//    }

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

//class L2CapPeripheralConnection: L2CapInternalConnection {
//    init(channel: CBL2CAPChannel) {
//        super.init()
//        self.channel = channel
//        channel.inputStream.delegate = self
//        channel.outputStream.delegate = self
//        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
//        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
//        channel.inputStream.open()
//        channel.outputStream.open()
//    }
//}
