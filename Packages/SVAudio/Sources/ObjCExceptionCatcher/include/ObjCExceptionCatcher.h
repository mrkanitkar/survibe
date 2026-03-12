#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Catches Objective-C exceptions thrown by a block and converts them to NSError.
///
/// AVAudioUnitSampler.loadSoundBankInstrument raises NSExceptions on
/// malformed SoundFont files. Swift's do/catch cannot intercept ObjC exceptions,
/// so this helper bridges them into Swift-friendly NSErrors.
///
/// @param block The block to execute.
/// @param error On return, an NSError if an NSException was raised.
/// @return YES if the block executed without raising, NO otherwise.
FOUNDATION_EXPORT BOOL SVAudioTryObjC(NS_NOESCAPE void (^_Nonnull block)(void),
                                       NSError *_Nullable __autoreleasing *_Nullable error);

NS_ASSUME_NONNULL_END
