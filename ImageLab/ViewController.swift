//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController   {

    //class properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridge()
    
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)
        
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
        
        // detect faces
        let faces = getFaces(img: inputImage)
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }

        var retImage = inputImage

        for face in faces {

            var leftEyeX = face.leftEyePosition.x
            var leftEyeY = face.leftEyePosition.y
            var rightEyeX = face.rightEyePosition.x
            var rightEyeY = face.rightEyePosition.y
            
            var mouth = face.mouthPosition
            
            var faceWidth = face.bounds.width
            var faceHeight = face.bounds.height
            
            //CGRect bounds for eye and mouth
            var leftEyeBounds = CGRect(x:leftEyeX-faceWidth/4,y:leftEyeY-faceHeight/4,width:faceWidth/3,height:faceHeight/3)
            
            var rightEyeBounds = CGRect(x:leftEyeX-faceWidth/4,y:leftEyeY-faceHeight/4,width:faceWidth/3,height:faceHeight/3)
            
            var mouthBounds = CGRect(x:mouth.x-faceWidth/9,y:mouth.y-faceHeight/4,width:faceWidth/5,height:faceHeight/2)
                
            self.bridge.setTransforms(self.videoManager.transform)
                        
            
            self.bridge.setImage(retImage,
                                 withBounds: face.bounds,
                                 andContext: self.videoManager.getCIContext())
            self.bridge.processImage()
            retImage = self.bridge.getImageComposite()
            
            //process mouth
            self.bridge.setImage(retImage,
                                 withBounds: mouthBounds,
                                 andContext: self.videoManager.getCIContext())
            self.bridge.processMouthImage()
            retImage = self.bridge.getImageComposite()
            
            //process leftEye
            self.bridge.setImage(retImage,
                                 withBounds: leftEyeBounds,
                                 andContext: self.videoManager.getCIContext())
            self.bridge.processEyeImage()
            retImage = self.bridge.getImageComposite()
            
            //process rightEye
            self.bridge.setImage(retImage,
                                 withBounds: leftEyeBounds,
                                 andContext: self.videoManager.getCIContext())

            self.bridge.processEyeImage()
            retImage = self.bridge.getImageComposite()
            

            //display head if smiling
            if(face.hasSmile){
                self.bridge.setImage(retImage,
                                     withBounds: face.bounds,
                                     andContext: self.videoManager.getCIContext())
                self.bridge.processHeadImage()
                retImage = self.bridge.getImageComposite()
            }
        }
        
        return retImage
    }
    
    //-----------FACE DETECTION
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    
    // change the type of processing done in OpenCV
    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .left:
            self.bridge.processType += 1
        case .right:
            self.bridge.processType -= 1
        default:
            break
            
        }
        
        stageLabel.text = "Stage: \(self.bridge.processType)"

    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
            if val {
                print("Flash return, no errors.")
            }
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

   
}

