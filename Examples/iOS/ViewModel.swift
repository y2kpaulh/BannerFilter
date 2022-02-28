//
//  ViewModel.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/02/28.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import UIKit
import PhotosUI

class ViewModel {
    var imageFilter = [ImageFilterData]()
    
    func configPhotosUI() {
        let requiredAccessLevel: PHAccessLevel = .readWrite
        PHPhotoLibrary.requestAuthorization(for: requiredAccessLevel) { authorizationStatus in
            switch authorizationStatus {
            case .limited:
                print("limited authorization granted")
            case .authorized:
                print("authorization granted")
            default:
                //FIXME: Implement handling for all authorizationStatus
                print("Unimplemented")
            }
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
    
    func isResizeTargetView(beginPoint: CGPoint, endPoint: CGPoint) -> ResizeOption {
        var resizeOption: ResizeOption = .none
        
        var isLeft = false, isRight = false, isUp = false, isDown = false
        
        if endPoint.x > beginPoint.x {
            isRight = true
        }
        if endPoint.x < beginPoint.x {
            isLeft = true
        }
        
        if endPoint.y > beginPoint.y {
            isDown = true
        }
        
        if endPoint.y < beginPoint.y {
            isUp = true
        }
        
        if isLeft && isUp {
            print("smaller")
            resizeOption = .smaller
        }
        else if isRight && isDown {
            print("bigger")
            resizeOption = .bigger
        }
        
        return resizeOption
    }
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let input = CGPointDistanceSquared(from: from, to: to)
        return sqrt(input)
    }
}
