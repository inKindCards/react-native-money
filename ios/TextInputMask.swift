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
                print("[MoneyInput] initializeMoneyInput(\(reactTag)): could not find view")
                return
            }

            guard let textView = RNMoneyInputHelper.getTextField(from: view) else {
                print("[MoneyInput] initializeMoneyInput(\(reactTag)): could not get UITextField")
                return
            }

            let locale = options["locale"] as? String
            let key = reactNode.stringValue

            let tfAddr = UInt(bitPattern: ObjectIdentifier(textView))

            // No-op if our delegate is already set on this exact UITextField.
            // Called from onFocus on every tap, so this fast-path is the common case.
            if let existingMask = self.masks[key], textView.delegate === existingMask {
                print("[MoneyInput] initializeMoneyInput(\(reactTag)): delegate already set (tf=0x\(String(tfAddr, radix: 16))), skipping")
                return
            }

            let existingDelegateType = type(of: textView.delegate as AnyObject)
            let viewAddr = UInt(bitPattern: ObjectIdentifier(view))
            print("[MoneyInput] initializeMoneyInput(\(reactTag)): currentDelegate=\(existingDelegateType) view=0x\(String(viewAddr, radix: 16)) textField=0x\(String(tfAddr, radix: 16))")

            // Determine the base delegate to wrap. When re-initializing after a freeze/unfreeze
            // the UITextField's delegate has been reset to RCTBackedTextFieldDelegateAdapter (or it
            // is a brand-new UITextField after recreation). In either case we use textView.delegate
            // directly as the base so we don't accidentally wrap our own MoneyInputDelegate.
            //
            // Do NOT subclass RCTBackedTextFieldDelegateAdapter — doing so registers a second
            // UIControlEventEditingChanged target and causes _updateState to fire twice per
            // keystroke, desyncing _mostRecentEventCount.
            // If we've initialized this input before, reuse the stored original delegate
            // (RCTBackedTextFieldDelegateAdapter). iOS 18+ may replace our delegate with
            // KCTextInputCompositeDelegate when multiple inputs are active — capturing that
            // as the base creates a circular forwarding chain that stack-overflows in
            // textFieldShouldEndEditing: (INKIND-APP-82Z).
            let baseDelegate = self.listeners[key]?.originalDelegate ?? textView.delegate
            let wrapper = MoneyInputDelegateWrapper(originalDelegate: baseDelegate)
            self.listeners[key] = wrapper

            let maskedDelegate = MoneyInputDelegate(localeIdentifier: locale) { [weak view] (tf, value) in
                guard let view = view else { return }
                let tfAddrNow = UInt(bitPattern: ObjectIdentifier(tf))
                print("[MoneyInput] onChangeListener(\(reactTag)): textField=0x\(String(tfAddrNow, radix: 16)) value=\(value)")
                RNMoneyInputHelper.sendChangeEvent(view, text: value)
            }
            maskedDelegate.listener = wrapper

            self.masks[key] = maskedDelegate

            RNMoneyInputHelper.tagTextField(asMoneyInput: textView)
            textView.delegate = maskedDelegate
            print("[MoneyInput] initializeMoneyInput(\(reactTag)): delegate set to MoneyInputDelegate, wrapping \(existingDelegateType)")
        }
    }

    @objc(cleanupMoneyInput:)
    func cleanupMoneyInput(reactNode: NSNumber) {
        let reactTag = reactNode.intValue
        let key = reactNode.stringValue

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            print("[MoneyInput] cleanupMoneyInput(\(reactTag)): masks.hasKey=\(self.masks[key] != nil) listeners.hasKey=\(self.listeners[key] != nil)")

            defer {
                self.masks.removeValue(forKey: key)
                self.listeners.removeValue(forKey: key)
                print("[MoneyInput] cleanupMoneyInput(\(reactTag)): removed from tracking dicts")
            }

            guard let view = self.bridge.uiManager.view(forReactTag: reactNode) else {
                print("[MoneyInput] cleanupMoneyInput(\(reactTag)): could not find view — skipping delegate restore")
                return
            }

            guard let textView = RNMoneyInputHelper.getTextField(from: view) else {
                print("[MoneyInput] cleanupMoneyInput(\(reactTag)): could not get UITextField — skipping delegate restore")
                return
            }

            let currentDelegateType = type(of: textView.delegate as AnyObject)
            let originalDelegateType = type(of: self.listeners[key]?.originalDelegate as AnyObject)
            print("[MoneyInput] cleanupMoneyInput(\(reactTag)): currentDelegate=\(currentDelegateType) restoring to \(originalDelegateType)")

            // Always restore — iOS may have replaced our delegate with KCTextInputCompositeDelegate
            // when the field became first responder. The identity check against self.masks[key]
            // would fail in that case, leaving the field permanently without its original delegate.
            textView.delegate = self.listeners[key]?.originalDelegate

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
