#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(RNMoneyInput, NSObject)


RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(formatMoney:(nonnull NSNumber *)value
                                        locale:(NSString *)locale)
RCT_EXTERN__BLOCKING_SYNCHRONOUS_METHOD(extractValue:(nonnull NSString *)value
                                        locale:(NSString *)locale)

RCT_EXTERN_METHOD(initializeMoneyInput:(nonnull NSNumber *)reactNode
                  options:(NSDictionary *)options)

RCT_EXTERN_METHOD(cleanupMoneyInput:(nonnull NSNumber *)reactNode)

@end
