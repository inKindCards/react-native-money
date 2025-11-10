#import "RNMoneyInputHelper.h"
#import <objc/runtime.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTTextInputComponentView.h>
#endif
#import <React/RCTBaseTextInputView.h>
#import <React/RCTUITextField.h>

// Associated object key for tagging MoneyInput text fields
static const void *MoneyInputTagKey = &MoneyInputTagKey;

// Store original shouldBeRecycled
static BOOL (*originalShouldBeRecycled)(Class, SEL) = NULL;

// Our replacement for shouldBeRecycled class method
static BOOL MoneyInput_shouldBeRecycled(Class cls, SEL _cmd) {    
    // Always return NO to prevent recycling of ALL TextInput views
    // This is necessary because we can't check instance properties in a class method
    return NO;
}

@implementation RNMoneyInputHelper

+ (void)setupRecyclingPrevention {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"MoneyInput: setupRecyclingPrevention called");
        
#ifdef RCT_NEW_ARCH_ENABLED
        // Only swizzle in Fabric (new architecture)
        Class textInputClass = NSClassFromString(@"RCTTextInputComponentView");
        if (textInputClass) {            
            // Try to add/swizzle shouldBeRecycled class method
            Class metaClass = object_getClass(textInputClass);
            SEL shouldBeRecycledSelector = @selector(shouldBeRecycled);
            Method existingMethod = class_getClassMethod(textInputClass, shouldBeRecycledSelector);
            
            if (existingMethod) {
                originalShouldBeRecycled = (BOOL (*)(Class, SEL))method_getImplementation(existingMethod);
                method_setImplementation(existingMethod, (IMP)MoneyInput_shouldBeRecycled);
            } else {
                // Add shouldBeRecycled class method - signature: BOOL (class method, no args)
                BOOL added = class_addMethod(metaClass, 
                                            shouldBeRecycledSelector,
                                            (IMP)MoneyInput_shouldBeRecycled,
                                            "B@:"); // B = BOOL, @ = id (self - class object), : = SEL
            }
        } else {
            NSLog(@"MoneyInput: RCTTextInputComponentView not found (expected in Fabric)");
        }
#else
        NSLog(@"MoneyInput: Fabric not enabled, skipping swizzle");
#endif
    });
}

+ (UITextField *)getTextFieldFromView:(UIView *)view {
#ifdef RCT_NEW_ARCH_ENABLED
    // Try Fabric (new architecture) first
    if ([view isKindOfClass:NSClassFromString(@"RCTTextInputComponentView")]) {
        // Try to get the backing text field through KVC
        UITextField *textField = nil;
        @try {
            textField = [view valueForKey:@"_backedTextInputView"];
            if (!textField) {
                textField = [view valueForKey:@"backedTextInputView"];
            }
        } @catch (NSException *exception) {
            NSLog(@"MoneyInput: Exception getting text field: %@", exception);
        }
        
        if (textField && [textField isKindOfClass:[UITextField class]]) {
            return textField;
        }
    }
#endif
    
    // Try Paper (old architecture)
    if ([view isKindOfClass:[RCTBaseTextInputView class]]) {
        RCTBaseTextInputView *textInputView = (RCTBaseTextInputView *)view;
        id backedView = textInputView.backedTextInputView;
        
        if (backedView && [backedView isKindOfClass:[UITextField class]]) {
            return (UITextField *)backedView;
        }
    }
    
    NSLog(@"MoneyInput: Could not extract UITextField from view of type %@", NSStringFromClass([view class]));
    return nil;
}

+ (void)tagTextFieldAsMoneyInput:(UITextField *)textField {
    // Tag this UITextField as a MoneyInput using associated objects
    objc_setAssociatedObject(textField, MoneyInputTagKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)untagTextFieldAsMoneyInput:(UITextField *)textField {
    // Remove the MoneyInput tag
    objc_setAssociatedObject(textField, MoneyInputTagKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)sendChangeEvent:(UIView *)view text:(NSString *)text {    
#ifdef RCT_NEW_ARCH_ENABLED
    // For Fabric (new architecture)
    if ([view isKindOfClass:NSClassFromString(@"RCTTextInputComponentView")]) {
        // In Fabric, we need to manually update the attributedText
        // and notify the component that the value changed
        @try {
            // Get the text field
            UITextField *textField = [view valueForKey:@"_backedTextInputView"];
            if (!textField) {
                textField = [view valueForKey:@"backedTextInputView"];
            }
            
            if (textField) {
                // Update the text field's text
                textField.text = text;
                
                // Trigger the text field's editing changed event
                // This will notify React Native of the change
                [textField sendActionsForControlEvents:UIControlEventEditingChanged];
            }
        } @catch (NSException *exception) {
            NSLog(@"MoneyInput: Exception sending change event: %@", exception);
        }
    }
#endif

    // For Paper (old architecture)
    if ([view isKindOfClass:[RCTBaseTextInputView class]]) {
        RCTBaseTextInputView *textInputView = (RCTBaseTextInputView *)view;
        
        // Get reactTag through KVC (not publicly exposed)
        NSNumber *reactTag = [textInputView valueForKey:@"reactTag"];
        
        // Get nativeEventCount
        NSInteger eventCount = 0;
        @try {
            eventCount = [[textInputView valueForKey:@"nativeEventCount"] integerValue];
        } @catch (NSException *exception) {
            eventCount = 0;
        }
        
        // Get the onChange callback
        RCTDirectEventBlock onChange = nil;
        @try {
            onChange = [textInputView valueForKey:@"onChange"];
        } @catch (NSException *exception) {
            // onChange not available
        }
        
        if (onChange) {
            onChange(@{
                @"text": text,
                @"target": reactTag,
                @"eventCount": @(eventCount)
            });
        }
        return;
    }
}

@end

