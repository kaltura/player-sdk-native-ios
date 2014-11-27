#import <Foundation/Foundation.h>

CG_INLINE BOOL __isIOS8() {
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    if ([[vComp objectAtIndex:0] intValue] == 8) {
        return YES;
    }
    
    return NO;
}

CG_EXTERN BOOL isIOS8();

#define isIOS8 __isIOS8