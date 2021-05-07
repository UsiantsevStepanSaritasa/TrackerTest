//
//  AlertPresenter.swift
//  HealthTestApp
//
//  Created by Denis Kovalev on 19.04.2021.
//

import UIKit

/// A helper class for presenting alert dialogs on view controllers
class AlertPresenter {
    /// Presents the alert dialog on target view controller with specified title, body message and actions
    class func presentAlertWith(title: String? = nil, message: String? = nil, actions: [UIAlertAction] = [], target: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alertController.addAction($0) }
        target.present(alertController, animated: true, completion: nil)
    }

    /// Presents simple alert dialog with title, body message and one button
    class func presentSimpleAlert(title: String? = nil, message: String? = nil, target: UIViewController, buttonText: String = "OK",
                                  buttonStyle: UIAlertAction.Style = .default, buttonAction: (() -> Void)? = nil)
    {
        let action = UIAlertAction(title: buttonText, style: buttonStyle, handler: { _ -> Void in buttonAction?() })
        presentAlertWith(title: title, message: message, actions: [action], target: target)
    }

    /// Presents the alert dialog with "Error" title, body message and the only OK button
    class func presentErrorAlert(title: String = "Error", message: String, target: UIViewController, buttonAction: (() -> Void)? = nil) {
        presentSimpleAlert(title: title, message: message, target: target, buttonAction: buttonAction)
    }

    class func presentTextFieldAlert(title: String? = nil,
                                     message: String? = nil,
                                     placeholder: String? = nil,
                                     target: UIViewController,
                                     buttonAction: ((String) -> Void)? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        controller.addTextField { field in
            field.placeholder = placeholder
            field.keyboardType = .decimalPad
        }
        
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak controller] _ in
            guard let field = controller?.textFields?.first else { return }
            buttonAction?(field.text ?? "")
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        target.present(controller, animated: true, completion: nil)
    }
}
