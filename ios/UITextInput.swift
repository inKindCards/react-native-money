//
//  UITextInput.swift
//  RNMoneyInput
//
//  Created by Nathan Horrigan on 14/01/2022.
//  Copyright © 2022 inKindCards. All rights reserved.
//

import UIKit

public extension UITextInput {
    
    var allText: String {
        get {
            guard let all: UITextRange = allTextRange
            else { return "" }
            return self.text(in: all) ?? ""
        }
        
        set(newText) {
            guard let all: UITextRange = allTextRange
            else { return }
            self.replace(all, withText: newText)
        }
    }
    
    var caretPosition: Int {
        get {
            if let responder = self as? UIResponder {
                // Workaround for non-optional `beginningOfDocument`, which could actually be nil if field doesn't have focus
                guard responder.isFirstResponder
                else { return allText.count }
            }
            
            if let range: UITextRange = selectedTextRange {
                let selectedTextLocation: UITextPosition = range.start
                return offset(from: beginningOfDocument, to: selectedTextLocation)
            } else {
                return 0
            }
        }
        
        set(newPosition) {
            if let responder = self as? UIResponder {
                // Workaround for non-optional `beginningOfDocument`, which could actually be nil if field doesn't have focus
                guard responder.isFirstResponder
                else { return }
            }
            
            if newPosition > allText.count {
                return
            }
            
            let from: UITextPosition = position(from: beginningOfDocument, offset: newPosition)!
            let to:   UITextPosition = position(from: from, offset: 0)!
            selectedTextRange = textRange(from: from, to: to)
        }
    }
    
    var allTextRange: UITextRange? {
        return self.textRange(from: self.beginningOfDocument, to: self.endOfDocument)
    }
    
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
