//
//  ImageSizeControlView.swift
//  enlargeView
//
//  Created by Inpyo Hong on 2022/02/24.
//

import UIKit
import Combine

enum ResizeOption: Int {
    case smaller = 0, bigger, none
}

class ImageSizeControlView: UIImageView {
    var panGesture = UIPanGestureRecognizer()
    var dragEvent = PassthroughSubject<(Int, CGPoint, CGPoint, CGPoint), Never>()
    
    private var lastSwipeBeginningPoint: CGPoint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        self.isUserInteractionEnabled = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragImg))
        self.addGestureRecognizer(panGesture)
        
        self.image = UIImage(named: "imgSize")!
        self.backgroundColor = .clear
    }
    
    @objc func dragImg(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        
        print("translation",translation)
        
        if sender.state == .began {
            lastSwipeBeginningPoint = sender.location(in: sender.view)
        } else { //if sender.state == .ended {
            guard let beginPoint = lastSwipeBeginningPoint else {
                return
            }
            
            let endPoint = sender.location(in: sender.view)
            // TODO: use the x and y coordinates of endPoint and beginPoint to determine which direction the swipe occurred.
            self.dragEvent.send((self.tag, beginPoint, endPoint, translation))
        }
    }
    
    func changeDataToImageArray(data: Data) -> [UIImage]? {
        print(data)
        
        let gifOptions = [
            kCGImageSourceShouldAllowFloat as String: true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String: true as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, gifOptions) else {
            debugPrint("Cannot create image source with data!")
            return nil
        }
        
        let framesCount = CGImageSourceGetCount(imageSource)
        var frameList = [UIImage]()
        
        for index in 0 ..< framesCount {
            if let cgImageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
                let uiImageRef = UIImage(cgImage: cgImageRef)
                frameList.append(uiImageRef)
            }
        }
        
        return frameList
    }
}
