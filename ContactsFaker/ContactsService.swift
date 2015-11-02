//
//  ContactsService.swift
//  ContactsFaker
//
//  Created by Alex Antonyuk on 11/2/15.
//  Copyright © 2015 Alex Antonyuk. All rights reserved.
//

import Foundation
import Contacts
import Fakery

class ContactsService {
	private let contactsStore = CNContactStore()
	private let faker = Faker(locale: "en_US")

	func requestAccess(callback: () -> ()) {
		contactsStore.requestAccessForEntityType(.Contacts) { status, error in
			dispatch_async(dispatch_get_main_queue(), callback)
		}
	}

	func generateContacts(number: Int, progress: (Float) -> (), callback: () -> ()) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			for i in 1...number {
				autoreleasepool {
					self.addContact()
				}
				dispatch_async(dispatch_get_main_queue()) {
					progress(Float(i) / Float(number))
				}
			}
			dispatch_async(dispatch_get_main_queue(), callback)
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

	func deleteAllContacts(callback: () -> ()) {
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
			dispatch_async(dispatch_get_main_queue(), callback)
		}
	}
}
