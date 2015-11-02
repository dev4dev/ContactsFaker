//
//  ViewController.swift
//  ContactsFaker
//
//  Created by Alex Antonyuk on 10/5/15.
//  Copyright © 2015 Alex Antonyuk. All rights reserved.
//

import UIKit
import Contacts

class ViewController: UIViewController {

	@IBOutlet weak var contactsCountLabel: UILabel!
	@IBOutlet weak var deleteStatusLabel: UILabel!
	@IBOutlet weak var countTextField: UITextField!
	@IBOutlet weak var progress: UIProgressView!

	let service = ContactsService()

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		service.requestAccess() {
			self.updateView()
		}
	}

	func updateView() {
		self.contactsCountLabel.text = String(service.contactsCount())
	}
}

// MARK: - UI Actions
extension ViewController {

	@IBAction func getContacts(sender: UIButton) {
		//		progress.progress = 0

		if let numberStr = countTextField.text, number = Int(numberStr) {
			service.generateContacts(number, progress: { [unowned self] in
					self.progress.progress = $0
				}, callback: {
					self.progress.progress = 0
					self.updateView()
			})
		}
	}

	@IBAction func onDeleteAllContacts(sender: UIButton) {
		deleteStatusLabel.text = "Deleting..."
		service.deleteAllContacts() { [unowned self] in
			self.deleteStatusLabel.text = "Done."
			self.updateView()
		}
	}
}
