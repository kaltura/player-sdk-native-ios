//
//  KPShareViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/4/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPShareViewController.h"
#import "KPShareManager.h"

@interface KPSharCell : UICollectionViewCell {
    UIImageView *icon;
}
@property (nonatomic, strong) UIImage *shareIcon;
@end

@implementation KPSharCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = self.center;
        [self addSubview:spinner];
        return self;
    }
    return nil;
}

- (void)setShareIcon:(UIImage *)shareIcon {
    if (!icon) {
        icon = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:icon];
    }
    icon.image = shareIcon;
}

@end

@interface KPShareViewController () <UICollectionViewDataSource, UICollectionViewDelegate, KPShareParams>{
    
    __weak IBOutlet UICollectionView *shareCollectionView;
    NSInteger shareIndex;
}

@end

static const NSString *ShareNameKey = @"name";

@implementation KPShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"KPShareViewController" bundle:shareBundle()];
    if (self) {
        return self;
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [shareCollectionView registerClass:[KPSharCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
}


- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UICollectionViewDatasource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return _shareProvidersArr.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KPSharCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier"
                                                                         forIndexPath:indexPath];
    
    cell.shareIcon = shareIcon(_shareProvidersArr[indexPath.row][ShareNameKey]);
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(59, 59);
}


#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    shareIndex = indexPath.row;
    NSString *strategyName = [_shareProvidersArr[indexPath.row][ShareNameKey] stringByAppendingString:@"Strategy"];
    Class startegyClass = NSClassFromString(strategyName);
    [KPShareManager shared].datasource = self;
    [KPShareManager shared].shareStrategyObject = [[startegyClass alloc] init];
    UIViewController *shareController = [[KPShareManager shared] shareWithCompletion:^(KPShareResults result, KPShareError *shareError) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    if (shareController) {
        [self presentViewController:shareController
                           animated:YES
                         completion:nil];
    }
}


#pragma mark KPShareParams
- (NSString *)shareLink {
    return _sharedURL;
}

- (NSString *)shareTitle {
    return @"Check out my video";
}

- (NSString *)shareIconName {
    return @"";
}

- (NSString *)shareDescription {
    return @"Check out the video";
}

- (NSString *)shareIconLink {
    return _shareIconLink;
}

- (NSString *)rootURL {
    return _shareProvidersArr[shareIndex][RootURLKey];
}

- (NSString *)redirectURL {
    return _shareProvidersArr[shareIndex][RedirectURLKey];
}

@end
