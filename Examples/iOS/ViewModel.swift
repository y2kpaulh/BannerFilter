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
    var controlBtnSize = CGSize(width: 30, height: 30)
    var currentResolution: CGSize = CGSize(width: 720, height: 1280)
    var screenRatio: CGSize {
        return CGSize(width: currentResolution.width/UIScreen.main.bounds.width, height: currentResolution.height/UIScreen.main.bounds.height)
    }
    
    var publishSizeRatio: CGSize {
        return CGSize(width: (UIScreen.main.bounds.size.width/currentResolution.width), height: (UIScreen.main.bounds.size.height/currentResolution.height))
    }
    
    var screenSizeRatio: CGSize {
        return CGSize(width: (currentResolution.width/UIScreen.main.bounds.size.width), height: (currentResolution.height/UIScreen.main.bounds.size.height))
    }
    
    var filterList = [ImageFilterData]()
    
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
                
                // fix orientation
                if let image = uiImageRef.upOrientationImage() {
                    frameList.append(image)
                }
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
            resizeOption = .smaller
        }
        else if isRight && isDown {
            resizeOption = .bigger
        }
        
        return resizeOption
    }
    
    func getTargetViewRect(_ resizeOption: ResizeOption, filterData: ImageFilterData, resizeValue: CGFloat,  bottomTrailingPoint: CGPoint) -> CGRect {
        var resultRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        var resultWidth: CGFloat = 0
        var resultHeight: CGFloat = 0
        var resultOrigin = CGPoint(x: 0, y: 0)
        var resultSize = CGSize(width: 0, height: 0)
        
        var scaleFactor: CGFloat = 0
        var targetLength: CGFloat = 0
        var changedWidth: CGFloat = 0
        let lastOuterImgFrame = filterData.menu.controlView.frame
        
        switch resizeOption {
        case .smaller:
            changedWidth = lastOuterImgFrame.width - (resizeValue * 2)
            let minLength = currentResolution.width * 0.1
            
            if changedWidth > minLength {
                targetLength = changedWidth
            } else {
                print("too small!")
                targetLength = minLength
            }
            
        case .bigger:
            changedWidth = lastOuterImgFrame.width + (resizeValue * 2)
            let maxLength = currentResolution.width * 0.9
            
            if changedWidth > maxLength {
                print("too big!")
                targetLength = maxLength
            } else {
                targetLength = changedWidth
            }
            
        default:
            break
        }
        
        scaleFactor = targetLength / filterData.data.info.ratio
        
        resultWidth = filterData.data.info.size.width * scaleFactor
        resultHeight = filterData.data.info.size.height * scaleFactor
        
        resultSize = CGSize(width: resultWidth, height: resultHeight)
        
        resultOrigin = CGPoint(x: bottomTrailingPoint.x - resultWidth + 5,
                               y: bottomTrailingPoint.y - resultHeight + 5)
        
        resultRect = CGRect(origin: resultOrigin, size: resultSize)
        
        return resultRect
    }
    
    func getTouchIndex(_ touchPoint: CGPoint) -> Int?{
        var isTouched = false
        var searchIndex: Int?
        
        for (index, filterData) in self.filterList.enumerated().reversed() {
            let filterRect = filterData.menu.controlView.frame
            if (touchPoint.x>=filterRect.minX && filterRect.maxX >= touchPoint.x) &&
                (touchPoint.y>=filterRect.minY && filterRect.maxY >= touchPoint.y) &&
                !isTouched {
                isTouched = true
                searchIndex = index
            }
        }
        return searchIndex
    }

    func getFilterIndex(_ viewId: Int) -> Int {
        return self.filterList.firstIndex {
           $0.data.id == viewId
       }!
    }
    
    func updateControlMenu(_ touchPoint: CGPoint) {
        let searchIndex = self.getTouchIndex(touchPoint)
//        let filterId = self.filterList[searchIndex].data.id
        
        UIView.animate(withDuration: 0.1) { [self] in
            self.filterList = self.filterList.map {
                var indexData = $0
                if let touchedIndex = searchIndex {
                    let filterId = self.filterList[touchedIndex].data.id
                    
                    if filterId == indexData.data.id {
                        indexData = displayFilterMenu(indexData, isTouched: true)
                    } else {
                        indexData = displayFilterMenu(indexData, isTouched: false)
                    }
                } else {
                    indexData = displayFilterMenu(indexData, isTouched: false)
                }
                
                return indexData
            }
        }
    }
    
    func displayFilterMenu(_ indexData: ImageFilterData, isTouched: Bool) -> ImageFilterData {
        indexData.menu.controlView.isUserInteractionEnabled = isTouched
        indexData.menu.sizeControl.isHidden = !isTouched
        indexData.menu.closeButton.isHidden = !isTouched
        
        return indexData
    }
    
    func updateFilterPosition(_ changeIndex:Int, _ changeFrame: CGRect) {
        //image filter scaling
        let publishPoint = CGPoint(
            x: changeFrame.origin.x * screenRatio.width,
            y: changeFrame.origin.y * screenRatio.height)
        
        let publishSize = CGSize(
            width: changeFrame.size.width * screenRatio.width,
            height: changeFrame.size.height * screenRatio.height)
        
        let publishRect = CGRect(origin: publishPoint, size: publishSize)
        
        // read index data
        var indexFilterData = filterList[changeIndex]
        
        //change Position
        indexFilterData.data.rect = publishRect
        indexFilterData.menu.sizeControl.center = CGPoint(x: changeFrame.maxX - 5,
                                                          y: changeFrame.maxY - 5)
        indexFilterData.menu.closeButton.center = CGPoint(x: changeFrame.maxX - 5,
                                                          y: changeFrame.origin.y + 5)
        // update index data
        filterList[changeIndex] = indexFilterData
    }
}

extension UIViewController {
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let input = CGPointDistanceSquared(from: from, to: to)
        return sqrt(input)
    }
}
