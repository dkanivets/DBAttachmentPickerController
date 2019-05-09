//
//  NYTPreviewPhoto.h
//  DBAttachmentPickerControllerExample
//
//  Created by Dmitry Kanivets on 5/9/19.
//  Copyright © 2019 Denis Bogatyrev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NYTPhotoViewer/NYTPhoto.h>


@interface NYTPreviewPhoto : NSObject <NYTPhoto>
    
    // Redeclare all the properties as readwrite for sample/testing purposes.
    @property (nonatomic) UIImage *image;
    @property (nonatomic) NSData *imageData;
    @property (nonatomic) UIImage *placeholderImage;
    @property (nonatomic) NSAttributedString *attributedCaptionTitle;
    @property (nonatomic) NSAttributedString *attributedCaptionSummary;
    @property (nonatomic) NSAttributedString *attributedCaptionCredit;
    
    @end

