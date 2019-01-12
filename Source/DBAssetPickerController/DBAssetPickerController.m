//
//  DBAssetPickerController.m
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
#import "DBAssetPickerController.h"
#import "DBAssetGroupsViewController.h"
#import "DBAssetItemsViewController.h"
#import "NSBundle+DBLibrary.h"

@interface DBAssetPickerController () <DBAssetGroupsViewControllerDelegate, DBAssetItemsViewControllerDelegate>

@end

@implementation DBAssetPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DBAssetGroupsViewController *groupController = [[DBAssetGroupsViewController alloc] initWithNibName:NSStringFromClass([DBAssetGroupsViewController class]) bundle:[NSBundle dbAttachmentPickerBundle]];
    groupController.assetMediaType = self.assetMediaType;
    groupController.assetGroupsDelegate = self;
    
//
//    for (NSNumber *assetCollectionSubtype in assetCollectionSubtypes) {
//        NSArray *collections = smartAlbums[assetCollectionSubtype];
//        for (PHAssetCollection *assetCollection in collections) {
//
//            PHFetchOptions *options = [PHFetchOptions new];
//            if (self.assetMediaType == PHAssetMediaTypeVideo || self.assetMediaType == PHAssetMediaTypeImage) {
//                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", self.assetMediaType];
//            }
//            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
//
//            if (fetchResult.count) {
//                [assetCollections addObject:assetCollection];
//            }
//        }
//    }
    
    PHFetchOptions *options = [PHFetchOptions new];
//    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    PHAssetCollection *assetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                                  subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                  options:options].firstObject;
//    assetCollection.assetCollectionSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary;
//        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
  
        DBAssetItemsViewController *itemsController = [[DBAssetItemsViewController alloc] initWithNibName:NSStringFromClass([DBAssetItemsViewController class]) bundle:[NSBundle dbAttachmentPickerBundle]];
    itemsController.assetMediaType = self.assetMediaType;
    itemsController.assetItemsDelegate = self;
    itemsController.assetCollection = assetCollection;
    
    [self setViewControllers:@[groupController, itemsController]];
}

#pragma mark - DBAssetGroupsViewControllerDelegate

- (void)DBAssetGroupsViewController:(DBAssetGroupsViewController *)controller didSelectAssetColoection:(PHAssetCollection *)assetCollection {
    DBAssetItemsViewController *itemsController = [[DBAssetItemsViewController alloc] initWithNibName:NSStringFromClass([DBAssetItemsViewController class]) bundle:[NSBundle dbAttachmentPickerBundle]];
    itemsController.assetMediaType = self.assetMediaType;
    itemsController.assetItemsDelegate = self;
    itemsController.assetCollection = assetCollection;
    [self pushViewController:itemsController animated:YES];
}

- (void)DBAssetGroupsViewControllerDidCancel:(DBAssetGroupsViewController *)controller {
    if ([self.assetPickerDelegate respondsToSelector:@selector(DBAssetPickerControllerDidCancel:)]) {
        [self.assetPickerDelegate DBAssetPickerControllerDidCancel:self];
    }
}

#pragma mark = DBAssetItemsViewControllerDelegate

- (void)DBAssetItemsViewController:(nonnull DBAssetItemsViewController *)controller didFinishPickingAssetArray:(nonnull NSArray<PHAsset *> *)assetArray {
    if ([self.assetPickerDelegate respondsToSelector:@selector(DBAssetPickerController:didFinishPickingAssetArray:)]) {
        [self.assetPickerDelegate DBAssetPickerController:self didFinishPickingAssetArray:assetArray];
    }
}

- (BOOL)DBAssetImageViewControllerAllowsMultipleSelection:(DBAssetItemsViewController *)controller {
    BOOL allowsMultipleSelection = NO;
    if ([self.assetPickerDelegate respondsToSelector:@selector(DBAssetPickerControllerAllowsMultipleSelection:)]) {
        allowsMultipleSelection = [self.assetPickerDelegate DBAssetPickerControllerAllowsMultipleSelection:self];
    }
    return allowsMultipleSelection;
}

@end
