import Foundation
import UIKit


/**
 ### MoneyInputListener
 
 Allows clients to obtain value extracted by the mask from user input.
 
 Provides callbacks from listened UITextField.
 */
@objc public protocol MoneyInputListener: UITextFieldDelegate {
    
    /**
     Callback to return extracted value and to signal whether the user has complete input.
     */
    @objc optional func textField(
        _ textField: UITextField,
        didFillMandatoryCharacters complete: Bool,
        didExtractValue value: String
    )
    
}


/**
 ### MoneyInputDelegate
 
 UITextFieldDelegate, which applies masking to the user input.
 Might be used as a decorator, which forwards UITextFieldDelegate calls to its own listener.
 */
@IBDesignable
open class MoneyInputDelegate: NSObject, UITextFieldDelegate {

    open weak var listener: MoneyInputListener?
    open var onChangeListener: ((_ textField: UITextField, _ value: String) -> ())?
    open var localeIdentifier = Locale.current.identifier
    
    
    public init(
        localeIdentifier: String?,
        onMaskedTextChangedCallback: ((_ textInput: UITextInput, _ value: String) -> ())? = nil
       ) {
           self.onChangeListener = onMaskedTextChangedCallback
           if (localeIdentifier != nil) { self.localeIdentifier = localeIdentifier! }
           super.init()
       }
    
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return listener?.textFieldShouldBeginEditing?(textField) ?? true
    }

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        listener?.textFieldDidBeginEditing?(textField)
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return listener?.textFieldShouldEndEditing?(textField) ?? true
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        listener?.textFieldDidEndEditing?(textField)
    }
    
    open func textFieldDidChangeSelection(_ textField: UITextField) {
        if (textField.text != nil) {
            let isSuffixSymbol = textField.text?.last?.isNumber == false
            if (isSuffixSymbol && textField.caretPosition > textField.text!.count - 2) {
                textField.caretPosition = textField.text!.count - 2
            }
        }
    }
    
    @available(iOS 10.0, *)
    open func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if listener?.textFieldDidEndEditing?(textField, reason: reason) != nil {
            listener?.textFieldDidEndEditing?(textField, reason: reason)
        } else {
            listener?.textFieldDidEndEditing?(textField)
        }
    }
    
    open func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        // Clean the text input
        let originalString = textField.text ?? ""
        let updatedText: String = replaceCharacters(inText: originalString, range: range, withCharacters: string)
        
        // Convert text input to formatted string
        let value = MoneyMask.unmask(input: updatedText)
        let (priceString, formatter) = MoneyMask.mask(value: value, locale: self.localeIdentifier)
        
        // Create reference to end of number section of string
        let isSuffixSymbol = priceString.last?.isNumber == false
        let endOfInput = isSuffixSymbol
            ? priceString.count - 2
            : priceString.count + 1
        
        // Is the cusor on leading edge of numbers?
        let isLeadingEdge = isSuffixSymbol
            ? range.location >= originalString.count - 3
            : range.location >= originalString.count - 1
        
        // Was this a deletion or middle insertion?
        let isDeletion = string.count == 0
        let isInsert = (textField.text?.count ?? 0) > 3 && !isDeletion && !isLeadingEdge
        
        // Update the displayed text
        textField.text = priceString
        
        // Adjust the cursor so that it doesn't get lost in the formatting
        if (value == 0) {
            textField.caretPosition = endOfInput
        }
        
        // If the cursor is at begining of field, reset it to the end
        else if (range.location == 0) {
            textField.caretPosition = endOfInput
        }
        
        // Was a digit deleted or inserted at the end?
        else if (isLeadingEdge) {
            textField.caretPosition = endOfInput
        }
        
        // Was a digit deleted in the middle?
        else if (isDeletion) {
            textField.caretPosition = range.location
        }
        
        // Was a digit inserted somewhere in the middle
        else if (isInsert) {
            textField.caretPosition = endOfInput
        }
        
        // IDK just go the end...
        else {
            textField.caretPosition = endOfInput
        }
        
        // Apply any offsets caused by new commas to the left of the cursor
        if (textField.caretPosition > 0) {
            let commasAfter = priceString.prefix(textField.caretPosition - 1).filter(formatter.groupingSeparator.contains).count
            let commasBefore = originalString.prefix(textField.caretPosition - 1).filter(formatter.groupingSeparator.contains).count
            let offset = commasAfter - commasBefore
            if (offset > 0 || !isLeadingEdge) {
                textField.caretPosition += offset
            }
        }
        
        // Update JS land
        if (onChangeListener != nil) {
            onChangeListener!(textField, priceString)
        }

        // Tell field to let us handle text updating
        return false
    }
 
    open func replaceCharacters(inText text: String, range: NSRange, withCharacters newText: String) -> String {
        if 0 < range.length {
            let result = NSMutableString(string: text)
            result.replaceCharacters(in: range, with: newText)
            return result as String
        } else {
            let result = NSMutableString(string: text)
            result.insert(newText, at: range.location)
            return result as String
        }
    }
}

class MoneyMask {
    // Converts a malformed input string into a double representation of money
    static func unmask(input: String) -> Double {
        // Remove any non-numeric chars and convert to cents in a double type
        let numbers = input.filter("0123456789".contains)
        let cents = Double(numbers) ?? 0
        return (cents / 100).round(to: 2)
    }
    
    // Converts a double of monet into a pretty formatted string
    static func mask(value: Double, locale: String) -> (String, NumberFormatter)  {
        // Create a currency formmater from locale
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: locale)

        // We'll force unwrap with the !, if you've got defined data you may need more error checking
        return (currencyFormatter.string(from: NSNumber(value: value))!, currencyFormatter)
    }
}
