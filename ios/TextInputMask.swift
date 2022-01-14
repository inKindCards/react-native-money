import Foundation

@objc(RNMoneyInput)
class TextInputMask: NSObject, RCTBridgeModule, MoneyInputListener {
    static func moduleName() -> String {
        "MoneyInput"
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        true
    }

    var methodQueue: DispatchQueue {
        bridge.uiManager.methodQueue
    }

    var bridge: RCTBridge!
    var masks: [String: MoneyInputDelegate] = [:]
    var listeners: [String: MoneyInputListener] = [:]
    
    @objc(formatMoney:locale:)
    func formatMoney(value: NSNumber, locale: NSNumber?) -> String {
        let (format, _) = MoneyMask.mask(value: value.doubleValue, locale: "en_US")
        return format
    }
    
    @objc(extractValue:)
    func extractValue(value: NSString) -> NSNumber {
        return NSNumber(value: MoneyMask.unmask(input: String(value)))
    }
    
    @objc(initializeMoneyInput:options:)
    func initializeMoneyInput(reactNode: NSNumber, options: NSDictionary) {
        bridge.uiManager.addUIBlock { (uiManager, viewRegistry) in
            DispatchQueue.main.async {
                guard let view = viewRegistry?[reactNode] as? RCTBaseTextInputView else { return }
                let textView = view.backedTextInputView as! RCTUITextField
            
                let locale = options["locale"] as? String
                let maskedDelegate = MoneyInputDelegate(localeIdentifier: locale) { (_, value) in
                    let textField = textView as! UITextField
                    view.onChange?([
                        "text": value,
                        "target": view.reactTag,
                        "eventCount": view.nativeEventCount,
                    ])
                }
                let key = reactNode.stringValue
                self.listeners[key] = MaskedRCTBackedTextFieldDelegateAdapter(textField: textView)
                maskedDelegate.listener = self.listeners[key]
                self.masks[key] = maskedDelegate

                textView.delegate = self.masks[key]
            }
        }
    }
}

class MaskedRCTBackedTextFieldDelegateAdapter : RCTBackedTextFieldDelegateAdapter, MoneyInputListener {}
