//
//  OpenCVBridge.h
//  LookinLive
//
//  Created by Eric Larson.
//  Copyright (c) Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "AVFoundation/AVFoundation.h"

#import "PrefixHeader.pch"

@interface OpenCVBridge : NSObject

@property (nonatomic) NSInteger processType;

@property NSInteger arrayID;
@property (strong, nonatomic) NSMutableArray* redArr;
@property (strong, nonatomic) NSMutableArray* greenArr;
@property (strong, nonatomic) NSMutableArray* blueArr;


-(void) initArrays;
// set the image for processing later
-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)rect
      andContext:(CIContext*)context;

//get the image raw opencv
-(CIImage*)getImage;

//get the image inside the original bounds
-(CIImage*)getImageComposite;

-(bool)peakFinding; //finding the peak among 3 indexes

-(bool)processFinger;
// call this to perfrom processing (user controlled for better transparency)



-(void)processImage;

// for the video manager transformations
-(void)setTransforms:(CGAffineTransform)trans;

-(void)loadHaarCascadeWithFilename:(NSString*)filename;

@end
