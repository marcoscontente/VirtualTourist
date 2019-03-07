//
//  UIViewController+Extensions.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 27/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import UIKit

extension UIViewController {

    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func showInfo(withTitle: String = "INFORMATION", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(ac, animated: true)
        }
    }
    
    func  save() {
        do {
            try CoreDataStack.shared().saveContext()
        } catch {
            showInfo(withTitle: "ERROR", withMessage: "Error while saving pin location: \(error)")
        }
    }
    
}
