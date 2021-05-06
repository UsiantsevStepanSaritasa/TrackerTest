//
//  TabBarController.swift
//  TrackerTest
//
//  Created by Stepan on 26.04.2021.
//

import UIKit

final class TabBarController: UITabBarController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let locationViewController = UINavigationController(rootViewController: LocationViewController())
        let bluetoothViewController = BluetoothViewController()
        let healthViewController = HealthViewController()

        viewControllers = [locationViewController, bluetoothViewController, healthViewController]
        locationViewController.tabBarItem = UITabBarItem(
            title: "Location",
            image: UIImage(systemName: "location"),
            tag: 1
        )
        bluetoothViewController.tabBarItem = UITabBarItem(
            title: "Bluetooth",
            image: UIImage(systemName: "wave.3.right.circle"),
            tag: 1
        )
        healthViewController.tabBarItem = UITabBarItem(
            title: "Health",
            image: UIImage(systemName: "suit.heart"),
            tag: 1
        )
        
        locationViewController.tabBarItem.selectedImage = UIImage(systemName: "location.fill")
        bluetoothViewController.tabBarItem.selectedImage = UIImage(systemName: "wave.3.right.circle.fill")
        healthViewController.tabBarItem.selectedImage = UIImage(systemName: "suit.heart.fill")
    }
}
