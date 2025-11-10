#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@class MoneyInputDelegate;

@interface RNMoneyInputHelper : NSObject

+ (void)setupRecyclingPrevention;
+ (UITextField * _Nullable)getTextFieldFromView:(UIView *)view;
+ (void)tagTextFieldAsMoneyInput:(UITextField *)textField;
+ (void)untagTextFieldAsMoneyInput:(UITextField *)textField;
+ (void)sendChangeEvent:(UIView *)view text:(NSString *)text;

@end

