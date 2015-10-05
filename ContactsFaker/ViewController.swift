//
//  ViewController.swift
//  ContactsFaker
//
//  Created by Alex Antonyuk on 10/5/15.
//  Copyright © 2015 Alex Antonyuk. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import Fakery

class ViewController: UIViewController {

	@IBOutlet weak var contactsCountLabel: UILabel!
	@IBOutlet weak var deleteStatusLabel: UILabel!
	@IBOutlet weak var countTextField: UITextField!
	let contactsStore = CNContactStore()
	let faker = Faker(locale: "en_US")
	@IBOutlet weak var progress: UIProgressView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		contactsStore.requestAccessForEntityType(.Contacts) { status, error in
			dispatch_async(dispatch_get_main_queue()) {
				self.updateView()
			}
		}
	}

	func updateView() {

		self.contactsCountLabel.text = String(contactsCount())
	}

}

extension ViewController {

	func contactsCount() -> Int {
		let predicate = CNContact.predicateForContactsInContainerWithIdentifier(contactsStore.defaultContainerIdentifier())
		do {
			let result = try self.contactsStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: [CNContactIdentifierKey])
			return result.count
		}
		catch _ {
			return 0
		}
	}

	func generateContacts(number: Int) {
		progress.progress = 0
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			for i in 0..<number {
				autoreleasepool {
					self.addContact()
				}
				dispatch_async(dispatch_get_main_queue()) {
					self.progress.progress = Float(i) / Float(number)
				}
			}
			dispatch_async(dispatch_get_main_queue()) {
				self.progress.progress = 0
				self.updateView()
			}
		}
	}

	func addContact() {
		let contact = CNMutableContact()
		contact.contactType = .Person

		contact.givenName = faker.name.firstName()
		contact.familyName = faker.name.lastName()
		if arc4random_uniform(1) == 0 {
			contact.namePrefix = faker.name.prefix()
		}
		contact.nickname = faker.internet.username()

		contact.jobTitle = faker.name.title()

		// phones
		let phone = CNPhoneNumber(stringValue: faker.phoneNumber.cellPhone())
		let phoneNumber = CNLabeledValue(label: CNLabelHome, value: phone)
		contact.phoneNumbers = [phoneNumber]

		// emails
		let email = CNLabeledValue(label: CNLabelHome, value: faker.internet.email())
		contact.emailAddresses = [email]

		let url = CNLabeledValue(label: CNLabelHome, value: faker.internet.url())
		contact.urlAddresses = [url]

		// address
		let address = CNMutablePostalAddress()
		address.country = faker.address.country()
		address.city = faker.address.city()
		address.state = faker.address.state()
		address.street = faker.address.streetAddress(includeSecondary: true)
		address.postalCode = faker.address.postcode()
		let addressValue = CNLabeledValue(label: CNLabelHome, value: address)
		contact.postalAddresses = [addressValue]

		// social
		let facebook = CNSocialProfile(urlString: faker.internet.url(), username: faker.internet.username(), userIdentifier: nil, service: CNSocialProfileServiceFacebook)
		let twitter = CNSocialProfile(urlString: faker.internet.url(), username: faker.internet.username(), userIdentifier: nil, service: CNSocialProfileServiceTwitter)
		contact.socialProfiles = [CNLabeledValue(label: CNLabelHome, value: facebook), CNLabeledValue(label: CNLabelHome, value: twitter)]

		let save = CNSaveRequest()
		save.addContact(contact, toContainerWithIdentifier: nil)
		try! contactsStore.executeSaveRequest(save)
	}

	func deleteAllContacts() {
		deleteStatusLabel.text = "Deleting..."
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let fetch = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey])
			fetch.mutableObjects = true
			try! self.contactsStore.enumerateContactsWithFetchRequest(fetch) { contact, _ in
				if let contact = contact.mutableCopy() as? CNMutableContact {
					let deleteReq = CNSaveRequest()
					deleteReq.deleteContact(contact)
					do {
						try self.contactsStore.executeSaveRequest(deleteReq)
					}
					catch _ {
						print("Failed")
					}
				}
			}
			dispatch_async(dispatch_get_main_queue()) {
				self.deleteStatusLabel.text = "Done."
				self.updateView()
			}
		}
	}
}

// MARK: - UI Actions
extension ViewController {

	@IBAction func get100Contacts(sender: UIButton) {
		generateContacts(100)
	}

	@IBAction func get1000Contacts(sender: UIButton) {
		generateContacts(1000)
	}

	@IBAction func getContacts(sender: UIButton) {
		if let numberStr = countTextField.text, number = Int(numberStr) {
			generateContacts(number)
		}
	}

	@IBAction func onDeleteAllContacts(sender: UIButton) {
		deleteAllContacts()
	}
}
