//
//  UIViewController+Extension.swift
//  TrackerTest
//
//  Created by Stepan on 23.04.2021.
//

import UIKit

extension UIViewController {
    func showError(_ error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)
    }
}
