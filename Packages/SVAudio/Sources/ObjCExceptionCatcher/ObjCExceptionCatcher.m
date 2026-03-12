#import "include/ObjCExceptionCatcher.h"

BOOL SVAudioTryObjC(NS_NOESCAPE void (^_Nonnull block)(void),
                     NSError *_Nullable __autoreleasing *_Nullable error) {
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: exception.reason ?: @"Unknown Objective-C exception",
                @"ExceptionName": exception.name ?: @"Unknown",
            };
            *error = [NSError errorWithDomain:@"com.survibe.objc-exception"
                                         code:-1
                                     userInfo:userInfo];
        }
        return NO;
    }
}
