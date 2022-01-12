#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNMoneyInput, NSObject)


RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(formatMoney:(nonnull NSNumber) value)
RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(extractValue:(nonnull NSString) value)

RCT_EXTERN_METHOD(setMask:(nonnull NSNumber *)reactNode
                  options:(NSDictionary *)option)

@end
