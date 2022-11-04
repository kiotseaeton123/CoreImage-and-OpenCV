//
//  OpenCVBridge.m
//  LookinLive
//
//  Created by Eric Larson.
//  Copyright (c) Eric Larson. All rights reserved.
//
//

#import "OpenCVBridge.hh"


using namespace cv;

@interface OpenCVBridge()
@property (nonatomic) cv::Mat image;
@property (strong,nonatomic) CIImage* frameInput;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGAffineTransform inverseTransform;
@property (atomic) cv::CascadeClassifier classifier;
@end

@implementation OpenCVBridge

@synthesize redArr = _redArr;
@synthesize greenArr = _greenArr;
@synthesize blueArr = _blueArr;

#pragma mark ===Write Your Code Here===

-(void)initArrays{//initialize array buffers
    self.redArr = [NSMutableArray arrayWithCapacity:100];
    self.greenArr = [NSMutableArray arrayWithCapacity:100];
    self.blueArr = [NSMutableArray arrayWithCapacity:100];
}
// basic variables for bpm calculation and
float total = 0.0;
float average = 0.0;
float numBeats = 0;
float frameCount = 0.0;//framecount that won't reset
float numFramesPerSample = 0;

char text[50];
char framesText[50];
char beatText[50];
int numFrames = 30;

-(bool)processFinger{ //2.1

    Scalar avgPixelIntensity;
    cv::Mat frame_gray,image_copy;

    cvtColor(_image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    //show rbg values
    sprintf(text,"Avg. B: %.0f, G: %.0f, R: %.0f", avgPixelIntensity.val[2],avgPixelIntensity.val[1],avgPixelIntensity.val[0]);
    cv::putText(_image, text, cv::Point(0, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
 
    //show and calculate bpm
    sprintf(beatText, "BPM %.0f", (numBeats/4/frameCount)*1800 );
    cv::putText(_image, beatText, cv::Point(0,130), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    
    //increment framecount and read data in buffer
    if ((avgPixelIntensity.val[2]<40 && avgPixelIntensity.val[1]<40) || (avgPixelIntensity.val[0]>200 && avgPixelIntensity.val[2]<50)) {
        frameCount = frameCount +1 ;
        
        if (self.arrayID < numFrames){ //when array full
            
            self.redArr[self.arrayID] = @(avgPixelIntensity.val[0]);
            self.greenArr[self.arrayID] = @(avgPixelIntensity.val[1]);
            self.blueArr[self.arrayID] = @(avgPixelIntensity.val[2]);
            
            NSNumber* temp = @(avgPixelIntensity.val[0]);
            total += [temp floatValue];
            if([temp floatValue]<average-.5){
                sprintf(framesText, "Beat");
                numBeats = numBeats + 1;
                cv::putText(_image, framesText, cv::Point(0,80), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
            }
        
            self.arrayID += 1;
            numFramesPerSample +=1;
            
            return true;
            
        }
        else {
            self.arrayID = 0;
            average = total/numFrames;
            printf("%f",average);
            printf("array out of bounds");
            total = 0.0;
        }
        return true;
    }
    else{// if finger is lifted
        self.arrayID = 0;
        return false;
    }
}

//add borders around head if person is smiling
-(void)processHeadImage{
    cv::Mat frame_gray,image_copy;

    cvtColor(_image, image_copy, CV_BGRA2BGR);
    Mat gauss = cv::getGaussianKernel(23, 17);
    cv::filter2D(image_copy, image_copy, -1, gauss);
    cvtColor(image_copy, _image, CV_BGR2BGRA);
}

//identify eyes in blurred box
-(void)processEyeImage{
    cv::Mat frame_gray,image_copy;

    cvtColor(_image, image_copy, CV_BGRA2BGR);
    Mat gauss = cv::getGaussianKernel(23, 17);
    cv::filter2D(image_copy, image_copy, -1, gauss);
    cvtColor(image_copy, _image, CV_BGR2BGRA);
  
}

//identify mouth in blurred box
-(void)processMouthImage{
    cv::Mat frame_gray,image_copy;

    cvtColor(_image, image_copy, CV_BGRA2BGR);
    Mat gauss = cv::getGaussianKernel(23, 17);
    cv::filter2D(image_copy, image_copy, -1, gauss);
    cvtColor(image_copy, _image, CV_BGR2BGRA);
}

#pragma mark Define Custom Functions Here
//identify multiple faces
-(void)processImage{
    
    cv::Mat frame_gray,image_copy;
    const int kCannyLowThreshold = 300;
    const int kFilterKernelSize = 5;

}


#pragma mark ====Do Not Manipulate Code below this line!====
-(void)setTransforms:(CGAffineTransform)trans{
    self.inverseTransform = trans;
    self.transform = CGAffineTransformInvert(trans);
}

-(void)loadHaarCascadeWithFilename:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    self.classifier = cv::CascadeClassifier([filePath UTF8String]);
}

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.transform = CGAffineTransformScale(self.transform, -1.0, 1.0);
        
        self.inverseTransform = CGAffineTransformMakeScale(-1.0,1.0);
        self.inverseTransform = CGAffineTransformRotate(self.inverseTransform, -M_PI_2);
        
        
    }
    return self;
}

#pragma mark Bridging OpenCV/CI Functions
// code manipulated from
// http://stackoverflow.com/questions/30867351/best-way-to-create-a-mat-from-a-ciimage
// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c


-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)faceRectIn
      andContext:(CIContext*)context{
    
    CGRect faceRect = CGRect(faceRectIn);
    faceRect = CGRectApplyAffineTransform(faceRect, self.transform);
    ciFrameImage = [ciFrameImage imageByApplyingTransform:self.transform];
    
    
    //get face bounds and copy over smaller face image as CIImage
    //CGRect faceRect = faceFeature.bounds;
    _frameInput = ciFrameImage; // save this for later
    _bounds = faceRect;
    CIImage *faceImage = [ciFrameImage imageByCroppingToRect:faceRect];
    CGImageRef faceImageCG = [context createCGImage:faceImage fromRect:faceRect];
    
    // setup the OPenCV mat fro copying into
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(faceImageCG);
    CGFloat cols = faceRect.size.width;
    CGFloat rows = faceRect.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    _image = cvMat;
    
    // setup the copy buffer (to copy from the GPU)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                      // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    //kCGImageAlphaLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), faceImageCG);
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(faceImageCG);
    
}

-(CIImage*)getImage{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        //kCGImageAlphaLast |
                                        kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
}

-(CIImage*)getImageComposite{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        //kCGImageAlphaLast |
                                        kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    // now apply transforms to get what the original image would be inside the Core Image frame
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    CIFilter* filt = [CIFilter filterWithName:@"CISourceAtopCompositing"
                          withInputParameters:@{@"inputImage":retImage,@"inputBackgroundImage":self.frameInput}];
    retImage = filt.outputImage;
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    return retImage;
}




@end
