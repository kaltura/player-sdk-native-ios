//
//  KPAssetRegistrationHelper.h
//  Pods
//
//  Created by Noam Tamim on 04/08/2016.
//
//

@import AVFoundation;
#import "KPLocalAssetsManager.h"

@interface KPAssetRegistrationHelper : NSObject

@property (nonatomic, copy) kLocalAssetRegistrationBlock assetRegistrationBlock;
@property BOOL refresh;

// Get an AVAssetResourceLoaderDelegate that can fetch and store a license.
// Imp: create an object that implements the protocol and talks to the uDRM.
-(id<AVAssetResourceLoaderDelegate>)createResourceLoaderDelegateWithError:(NSError**)error;

// Notify the SDK that download is complete.
// Imp: register the asset (store metadata). Call the assetRegistrationBlock when done.
-(BOOL)saveAssetAtPath:(NSURL*)localPath;

// Maybe other utility methods.

@end



@interface KPAssetRegistrationHelper (Factory)
+(instancetype)helperForAsset:(KPPlayerConfig *)assetConfig flavor:(NSString *)flavorId;
@end
