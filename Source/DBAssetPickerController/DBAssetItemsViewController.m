//
//  DBAssetItemsViewController.m
//  DBAttachmentPickerController
//
//  Created by Denis Bogatyrev on 14.03.16.
//
//  The MIT License (MIT)
//  Copyright (c) 2016 Denis Bogatyrev.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

@import Photos;
#import "DBAssetItemsViewController.h"
#import "DBThumbnailPhotoCell.h"
#import "NSIndexSet+DBLibrary.h"
#import "NSBundle+DBLibrary.h"
#import "DBAttachmentPickerController.h"
#import "DBAssetPickerController.h"

static const NSInteger kNumberItemsPerRowPortrait = 4;
static const NSInteger kNumberItemsPerRowLandscape = 7;
static const CGFloat kDefaultItemOffset = 1.f;
static NSString *const kPhotoCellIdentifier = @"DBThumbnailPhotoCellID";

@interface DBAssetItemsViewController () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) PHFetchResult *assetsFetchResults;
@property (strong, nonatomic) PHCachingImageManager *imageManager;
@property (strong, nonatomic) NSMutableArray *selectedIndexPathArray;
@property (strong, nonatomic) UILabel *countButton;

@end

@implementation DBAssetItemsViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedIndexPathArray = [NSMutableArray arrayWithCapacity:10];
    
    self.navigationItem.title = self.assetCollection.localizedTitle;
    
    if ([self.assetItemsDelegate respondsToSelector:@selector(DBAssetImageViewControllerAllowsMultipleSelection:)]) {
        if ( [self.assetItemsDelegate DBAssetImageViewControllerAllowsMultipleSelection:self] ) {
            UIBarButtonItem *sendItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Attach", nil)
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(attachButtonDidSelect:)];
            
            self.countButton = [[UILabel alloc] init];
            self.countButton.frame = CGRectMake(0, 0, 16, 16);
            self.countButton.clipsToBounds = YES;
            self.countButton.layer.masksToBounds = YES;
            self.countButton.layer.cornerRadius = 8;
            self.countButton.backgroundColor = self.countButton.tintColor;
            self.countButton.font = [UIFont boldSystemFontOfSize: 12];
            NSString *text = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.selectedIndexPathArray.count];
            self.countButton.text = text;
            self.countButton.hidden = (([text  isEqual: @""]) || (text == nil) || ([text  isEqual: @"0"]));
            self.countButton.textColor = [UIColor whiteColor];
            self.countButton.textAlignment = NSTextAlignmentCenter;
            UIBarButtonItem *countItem = [[UIBarButtonItem alloc] initWithCustomView: self.countButton];
            
            self.navigationItem.rightBarButtonItems = @[sendItem, countItem];
        }
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.sectionInset = UIEdgeInsetsMake(kDefaultItemOffset, kDefaultItemOffset, kDefaultItemOffset, kDefaultItemOffset);
    flowLayout.minimumLineSpacing = kDefaultItemOffset;
    flowLayout.minimumInteritemSpacing = kDefaultItemOffset;
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.allowsMultipleSelection = YES;
    
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self.imageManager stopCachingImagesForAllAssets];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([DBThumbnailPhotoCell class]) bundle:[NSBundle dbAttachmentPickerBundle]] forCellWithReuseIdentifier:kPhotoCellIdentifier];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIButton *cancelButton = [[UIButton alloc] init];
    [self.view addSubview: cancelButton];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    if (@available(iOS 11.0, *)) {
        [cancelButton.heightAnchor constraintEqualToConstant:44 + UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom].active = YES;
    } else {
        [cancelButton.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    [cancelButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [cancelButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    cancelButton.backgroundColor = [UIColor colorWithRed:(247.0f/255.0f) green:(247.0f/255.0f) blue:(247.0f/255.0f) alpha:1];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:self.view.tintColor forState: UIControlStateNormal];
    cancelButton.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
    cancelButton.layer.borderWidth = 1 / [[UIScreen mainScreen] scale];
    DBAssetPickerController *controller = (DBAssetPickerController*)self.navigationController;
    
    [cancelButton addTarget:controller action:@selector(DBAssetGroupsViewControllerDidCancel:) forControlEvents: UIControlEventTouchUpInside];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - Actions

- (void)attachButtonDidSelect:(UIBarButtonItem *)sender {
    if ([self.assetItemsDelegate respondsToSelector:@selector(DBAssetItemsViewController:didFinishPickingAssetArray:)]) {
        [self.assetItemsDelegate DBAssetItemsViewController:self didFinishPickingAssetArray:[self getSelectedAssetArray]];
    }
}

#pragma mark Helpers

- (NSArray *)getSelectedAssetArray {
    NSArray *selectedItems = self.selectedIndexPathArray;
    NSMutableArray *assetArray = [NSMutableArray arrayWithCapacity:selectedItems.count];
    for (NSIndexPath *indexPath in selectedItems) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assetArray addObject:asset];
    }
    return [assetArray copy];
}

#pragma mark - Accessors

- (void)setAssetCollection:(PHAssetCollection *)assetCollection {
    _assetCollection = assetCollection;
    
    [self updateFetchRequest];
    [self.collectionView reloadData];
}

#pragma mark - Fetching Assets

- (void)updateFetchRequest {
    if (self.assetCollection) {
        PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
        allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        if (self.assetMediaType == PHAssetMediaTypeVideo || self.assetMediaType == PHAssetMediaTypeImage) {
            allPhotosOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", self.assetMediaType];
        }
        
        self.assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:allPhotosOptions];
        [self.collectionView reloadData];
    } else {
        self.assetsFetchResults = nil;
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
        
        if (collectionChanges) {
            self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                [self.collectionView reloadData];
            } else {
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [self.collectionView deleteItemsAtIndexPaths:[removedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [self.collectionView insertItemsAtIndexPaths:[insertedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [self.collectionView reloadItemsAtIndexPaths:[changedIndexes indexPathsFromIndexesWithSection:0]];
                    }
                } completion:nil];
            }
            [self.imageManager stopCachingImagesForAllAssets];
            
            for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems]) {
                [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
            }
            [self.selectedIndexPathArray removeAllObjects];
        }
    });
}

#pragma mark - UICollectionView DataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DBThumbnailPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DBThumbnailPhotoCell alloc] init];
    }
    
    if ([self.selectedIndexPathArray containsObject:indexPath]) {
        cell.selectorCheckBox.on = TRUE;
    } else {
        cell.selectorCheckBox.on = NO;
    }
    [self configurePhotoCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configurePhotoCell:(DBThumbnailPhotoCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    cell.tintColor = self.collectionView.tintColor;
    cell.identifier = asset.localIdentifier;
    cell.needsDisplayEmptySelectedIndicator = NO;
    cell.indexPath = indexPath;
    cell.selectButtonTapHandler = ^(NSIndexPath *indexPath) {
        if (self.selectedIndexPathArray.count < 10) {
            [self.selectedIndexPathArray addObject:indexPath];
            NSString *text = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.selectedIndexPathArray.count];
            self.countButton.text = text;
            
            [UIView animateWithDuration:0.4 animations:^{
                self.countButton.hidden = (([text  isEqual: @""]) || (text == nil) || ([text  isEqual: @"0"]));
            }];
            BOOL allowsMultipleSelection = NO;
            if ([self.assetItemsDelegate respondsToSelector:@selector(DBAssetImageViewControllerAllowsMultipleSelection:)]) {
                allowsMultipleSelection = [self.assetItemsDelegate DBAssetImageViewControllerAllowsMultipleSelection:self];
            }
            if ( !allowsMultipleSelection ) {
                [self attachButtonDidSelect:nil];
            }
        } else {
            cell.selectorCheckBox.on = NO;
        }
    };
    cell.unselectButtonTapHandler = ^(NSIndexPath *indexPath) {
        [self.selectedIndexPathArray removeObject:indexPath];
        NSString *text = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.selectedIndexPathArray.count];
        self.countButton.text = text;
        [UIView animateWithDuration:0.4 animations:^{
            self.countButton.hidden = (([text  isEqual: @""]) || (text == nil) || ([text  isEqual: @"0"]));
        }];
        
    };
    [self.imageManager cancelImageRequest:cell.phImageRequestID];
    
    [cell.assetImageView configureWithAssetMediaType:asset.mediaType subtype:asset.mediaSubtypes];
    
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
        formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
        cell.durationLabel.text = [formatter stringFromTimeInterval:asset.duration];
    } else {
        cell.durationLabel.text = nil;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = [self collectionItemCellSizeAtIndexPath:indexPath];
    CGSize scaledThumbnailSize = CGSizeMake( size.width * scale, size.height * scale );
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    
    cell.phImageRequestID = [self.imageManager requestImageForAsset:asset
                                 targetSize:scaledThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:options
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if ([cell.identifier isEqualToString:asset.localIdentifier]) {
                                      cell.assetImageView.image = result;
                                  }
                              }];
    
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndexPathArray.count >= 10) {
        return NO;
    } else {
        return YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//
//    [self.selectedIndexPathArray addObject:indexPath];
//    NSString *text = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.selectedIndexPathArray.count];
//    self.countButton.text = text;
//    self.countButton.hidden = (([text  isEqual: @""]) || (text == nil) || ([text  isEqual: @"0"]));
//    BOOL allowsMultipleSelection = NO;
//    if ([self.assetItemsDelegate respondsToSelector:@selector(DBAssetImageViewControllerAllowsMultipleSelection:)]) {
//        allowsMultipleSelection = [self.assetItemsDelegate DBAssetImageViewControllerAllowsMultipleSelection:self];
//    }
//    if ( !allowsMultipleSelection ) {
//        [self attachButtonDidSelect:nil];
//    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
//    [self.selectedIndexPathArray removeObject:indexPath];
//    NSString *text = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)self.selectedIndexPathArray.count];
//    self.countButton.text = text;
//    self.countButton.hidden = (([text  isEqual: @""]) || (text == nil) || ([text  isEqual: @"0"]));
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self collectionItemCellSizeAtIndexPath:indexPath];
}

#pragma mark Helpers

- (CGSize)collectionItemCellSizeAtIndexPath:(NSIndexPath *)indexPath {
    if (self.assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumPanoramas) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        const CGFloat coef = (CGFloat)asset.pixelWidth / (CGFloat)asset.pixelHeight;
        CGFloat itemWidth = CGRectGetWidth(self.collectionView.bounds) - kDefaultItemOffset *2;
        return CGSizeMake( itemWidth, itemWidth / coef );
    } else {
        NSInteger numberOfItems = [self numberOfItemsPerRow];
        CGFloat itemWidth = floorf( ( CGRectGetWidth(self.collectionView.bounds) - kDefaultItemOffset * ( numberOfItems + 1 ) ) / numberOfItems );
        return CGSizeMake(itemWidth, itemWidth);
    }
}

- (NSInteger)numberOfItemsPerRow {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    const BOOL isLandscape = ( orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    return isLandscape ? kNumberItemsPerRowLandscape : kNumberItemsPerRowPortrait;
}

@end
