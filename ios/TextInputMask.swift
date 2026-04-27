import Foundation
import React

@objc(RNMoneyInput)
class TextInputMask: NSObject, RCTBridgeModule, MoneyInputListener {
    static func moduleName() -> String {
        "RNMoneyInput"
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        RNMoneyInputHelper.setupRecyclingPrevention()
        return true
    }

    @objc var bridge: RCTBridge!
    var masks: [String: MoneyInputDelegate] = [:]
    var listeners: [String: MoneyInputDelegateWrapper] = [:]

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

            guard let textView = RNMoneyInputHelper.getTextField(from: view) else {
                print("MoneyInput: Could not get UITextField from view")
                return
            }

            let locale = options["locale"] as? String
            let key = reactNode.stringValue

            // Save the existing delegate (RCTBackedTextFieldDelegateAdapter set by RCTUITextField)
            // and wrap it with a forwarding proxy. Do NOT subclass RCTBackedTextFieldDelegateAdapter
            // — doing so would register a second UIControlEventEditingChanged target and cause
            // _updateState to fire twice per keystroke, desyncing _mostRecentEventCount.
            let wrapper = MoneyInputDelegateWrapper(originalDelegate: textView.delegate)
            self.listeners[key] = wrapper

            let maskedDelegate = MoneyInputDelegate(localeIdentifier: locale) { (_, value) in
                RNMoneyInputHelper.sendChangeEvent(view, text: value)
            }
            maskedDelegate.listener = wrapper

            self.masks[key] = maskedDelegate

            RNMoneyInputHelper.tagTextField(asMoneyInput: textView)
            textView.delegate = maskedDelegate
        }
    }

    @objc(cleanupMoneyInput:)
    func cleanupMoneyInput(reactNode: NSNumber) {
        let reactTag = reactNode.intValue
        let key = reactNode.stringValue

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            defer {
                self.masks.removeValue(forKey: key)
                self.listeners.removeValue(forKey: key)
            }

            guard let view = self.bridge.uiManager.view(forReactTag: reactNode) else {
                print("MoneyInput: cleanup — could not find view with tag \(reactTag)")
                return
            }

            guard let textView = RNMoneyInputHelper.getTextField(from: view) else {
                return
            }

            // Only restore if our delegate is still set (nothing else replaced it)
            if textView.delegate === self.masks[key] {
                textView.delegate = self.listeners[key]?.originalDelegate
            }

            RNMoneyInputHelper.untagTextField(asMoneyInput: textView)
        }
    }

    @objc func invalidate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.masks.removeAll()
            self.listeners.removeAll()
        }
    }
}
