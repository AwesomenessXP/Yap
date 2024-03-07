//
//  MyLabel.swift
//  AggieStash
//
//  Created by Haskell Macaraig on 1/18/24.
//

import SwiftUI
import PhoneNumberKit

class PhoneNumModel: ObservableObject {
    @Published var text: String = ""
    @Published var buttonShown: Double = 0
    @Published var isDisabled: Bool = true
    @Published var color: Color = .red
    
    let MAXDIGITS = 10
    
    // Remove extra characters then count the string
    func unformatNum(number: String) -> String {
        let charToRemove: Set<Character> = [")", " ", "(", "-"]
        return number.filter({
            !charToRemove.contains($0)
        })
    }
    
    // Mutate the user inputted number if formatted correctly
    func asYouType(number: String, phoneNumberKit: PhoneNumberKit,
                   formattedNumber: Binding<String>) -> String {
        guard let phoneNumber = try? phoneNumberKit.parse(
            number, withRegion: "US", ignoreType: true
        ) else { return ""}
        return phoneNumberKit.format(phoneNumber, toType: .e164)
    }

    // Update the label based on validity of user's number
    func updateLabel(number: String) {
        let unformatted = unformatNum(number: number)
        if (unformatted.count < MAXDIGITS) {
            self.text = "Insufficient phone number length"
            self.buttonShown = 0
            self.isDisabled = true
            self.color = .red
        }
        else {
            self.text = "Proceed to OTP for phone number verification"
            self.buttonShown = 1
            self.isDisabled = false
            self.color = .green
        }
    }
}

