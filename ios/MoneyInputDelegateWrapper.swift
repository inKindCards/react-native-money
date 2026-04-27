import Foundation
import UIKit

class MoneyInputDelegateWrapper: NSObject, MoneyInputListener {
    weak var originalDelegate: UITextFieldDelegate?

    init(originalDelegate: UITextFieldDelegate?) {
        self.originalDelegate = originalDelegate
        super.init()
    }

    // RCTBackedTextFieldDelegateAdapter only implements the reason-less variant,
    // so handle the reason variant here and forward without reason.
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        originalDelegate?.textFieldDidEndEditing?(textField)
    }

    // Forward any UITextFieldDelegate selector the original responds to.
    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) { return true }
        return originalDelegate?.responds(to: aSelector) ?? false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if originalDelegate?.responds(to: aSelector) ?? false {
            return originalDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
}
