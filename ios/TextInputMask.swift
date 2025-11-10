import Foundation
import React

@objc(RNMoneyInput)
class TextInputMask: NSObject, RCTBridgeModule, MoneyInputListener {
    static func moduleName() -> String {
        "RNMoneyInput"
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        // Setup swizzling on first call (this is called early by React Native)
        RNMoneyInputHelper.setupRecyclingPrevention()
        return true
    }

    @objc var bridge: RCTBridge!
    var masks: [String: MoneyInputDelegate] = [:]
    var listeners: [String: MoneyInputListener] = [:]
    
    @objc(formatMoney:locale:)
    func formatMoney(value: NSNumber, locale: NSString?) -> String {
        let (format, _) = MoneyMask.mask(value: value.doubleValue, locale: String(locale ?? "en_US"))
        return format
    }
    
    @objc(extractValue:locale:)
    func extractValue(value: NSString, locale: NSString?) -> NSNumber {
        return NSNumber(value: MoneyMask.unmask(input: String(value), locale: String(locale ?? "en_US")))
    }
    
    @objc(initializeMoneyInput:options:)
    func initializeMoneyInput(reactNode: NSNumber, options: NSDictionary) {
        let reactTag = reactNode.intValue
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let view = self.bridge.uiManager.view(forReactTag: reactNode) else {
                print("MoneyInput: Could not find view with tag \(reactTag)")
                return
            }
            
            // Use the Objective-C++ helper to extract the UITextField
            // This works for both old and new architecture
            guard let textView = RNMoneyInputHelper.getTextField(from: view) else {
                print("MoneyInput: Could not get UITextField from view")
                return
            }
            
            let locale = options["locale"] as? String
            
            // The delegate will modify the text and notify React Native
            let maskedDelegate = MoneyInputDelegate(localeIdentifier: locale) { (textInput, value) in
                // Send the change event back to React Native
                RNMoneyInputHelper.sendChangeEvent(view, text: value)
            }
            
            let key = reactNode.stringValue
            
            // Only set up the listener adapter if it's an RCTUITextField (Paper architecture)
            if let rctTextField = textView as? RCTUITextField {
                self.listeners[key] = MaskedRCTBackedTextFieldDelegateAdapter(textField: rctTextField)
                maskedDelegate.listener = self.listeners[key]
            } else {
                // For Fabric, don't use the adapter
                maskedDelegate.listener = nil
            }
            
            self.masks[key] = maskedDelegate
            
            // Tag the UITextField as a MoneyInput to prevent recycling
            RNMoneyInputHelper.tagTextField(asMoneyInput: textView)
            
            textView.delegate = self.masks[key]
        }
    }
    
    @objc func invalidate() {
        print("MoneyInput: Bridge invalidated, cleaning up all delegates")
        
        // Clear all delegates on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Since MoneyInput views aren't recycled (shouldBeRecycled returns NO),
            // they'll be destroyed, so we just need to clear our tracking
            self.masks.removeAll()
            self.listeners.removeAll()
        }
    }
}

class MaskedRCTBackedTextFieldDelegateAdapter : RCTBackedTextFieldDelegateAdapter, MoneyInputListener {}
