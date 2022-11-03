
//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class BViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
    // used to stabilize the the torch so that it waits 50 frames to turn off the flash to avoid blinking
    var framesCount:Int = 50
    
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.bridge.initArrays()
        
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    func processImageSwift(inputImage:CIImage) -> CIImage{
        var retImage = inputImage
        
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        if framesCount < 50 {
            framesCount += 1 //inc every frame
        }
        
        if self.bridge.processFinger() {
            self.videoManager.turnOnFlashwithLevel(1)
        } else {
            
            if framesCount >= 50{
                self.videoManager.turnOffFlash()
                framesCount = 0
            }
        }
        //self.bridge.processFinger()
        retImage = self.bridge.getImage()
         
  
        return retImage
    }
    

   
}
