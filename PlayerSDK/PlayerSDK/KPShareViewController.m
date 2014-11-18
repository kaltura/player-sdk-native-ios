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
    
    UICollectionView *shareCollectionView;
    UINavigationBar *navBar;
    NSInteger shareIndex;
}

@end

static const NSString *ShareNameKey = @"name";

@implementation KPShareViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    [self initializeNavigationBar];
    [self initializeCollectionView];
}

- (void)initializeNavigationBar {
    navBar = [[UINavigationBar alloc] initWithFrame:(CGRect){0, 20, self.view.frame.size.width, 44.0}];
    UINavigationItem *titleItem = [UINavigationItem new];
    titleItem.title = @"Share";
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(cancelPressed:)];
    titleItem.leftBarButtonItem = dismissButton;
    [navBar pushNavigationItem:titleItem animated:YES];
    [self.view addSubview:navBar];
}

- (void)initializeCollectionView {
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = (UIEdgeInsets){20, 20, 20, 20};
    layout.itemSize = (CGSize){59, 59};
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    CGFloat collectionViewY = navBar.frame.origin.y + navBar.frame.size.height;
    CGRect collectionViewFrame = (CGRect){0, collectionViewY, self.view.frame.size.width, self.view.frame.size.height - collectionViewY};
    shareCollectionView=[[UICollectionView alloc] initWithFrame:collectionViewFrame
                                           collectionViewLayout:layout];
    shareCollectionView.alwaysBounceVertical = YES;
    [shareCollectionView setDataSource:self];
    [shareCollectionView setDelegate:self];
    
    [shareCollectionView registerClass:[KPSharCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [shareCollectionView setBackgroundColor:[UIColor lightGrayColor]];
    
    [self.view addSubview:shareCollectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)cancelPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return _shareProvidersArr.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __block KPSharCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier"
                                                                         forIndexPath:indexPath];
    
    [KPShareManager fetchShareIcon:_shareProvidersArr[indexPath.row][ShareNameKey]
                        completion:^(UIImage *icon, NSError *error) {
                            if (icon) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    cell.shareIcon = icon;
                                });
                            }
                        }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(59, 59);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    shareIndex = indexPath.row;
    NSString *strategyName = [_shareProvidersArr[indexPath.row][ShareNameKey] stringByAppendingString:@"Strategy"];
    Class startegyClass = NSClassFromString(strategyName);
    [KPShareManager shared].datasource = self;
    [KPShareManager shared].shareStrategyObject = [[startegyClass alloc] init];
    UIViewController *shareController = [[KPShareManager shared] shareWithCompletion:^(KPShareResults result, KPShareError *shareError) {
        
    }];
    
    if (shareController) {
        [self presentViewController:shareController
                           animated:YES
                         completion:nil];
    }
}

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
    return @"";
}

- (NSString *)rootURL {
    return _shareProvidersArr[shareIndex][RootURLKey];
}

- (NSString *)redirectURL {
    return _shareProvidersArr[shareIndex][RedirectURLKey];
}

- (NSString *)facebookAppID {
    return nil;
}
@end
