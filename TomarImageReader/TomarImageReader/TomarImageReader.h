//
//  TomarImageReader.h
//  TomarImageReader
//
//  Created by Prabhat Singh on 12/16/16.
//  Copyright © 2016 Prabhat Singh Tomar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//! Project version number for TomarImageReader.
FOUNDATION_EXPORT double TomarImageReaderVersionNumber;

//! Project version string for TomarImageReader.
FOUNDATION_EXPORT const unsigned char TomarImageReaderVersionString[];


@protocol TomarImageReaderDelegate<NSObject>
@required
-(void) sucessWithText:(nullable NSDictionary*)cardInfo;
-(void) failedTextReader:(nullable NSError*) error;
@end

@interface TomarImageReader: NSObject
@property (nonatomic, weak, nullable) id <TomarImageReaderDelegate> delegate;
- (void) performRecognitionWithImage:(UIImage* _Nonnull)image;
@end




