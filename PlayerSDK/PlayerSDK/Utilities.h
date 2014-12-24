#import <Foundation/Foundation.h>
#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>

CG_INLINE BOOL __isIOS8() {
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    if ([[vComp objectAtIndex:0] intValue] == 8) {
        return YES;
    }
    
    return NO;
}

CG_INLINE NSString *__idfa() {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

CG_EXTERN BOOL isIOS8();
CG_EXTERN NSString *idfa();

#define isIOS8 __isIOS8
#define idfa __idfa