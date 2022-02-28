//
//  ImageFilterMenuView.swift
//  ShallWeShop
//
//  Created by Inpyo Hong on 2020/08/06.
//  Copyright © 2020 Epiens Corp. All rights reserved.
//

import UIKit
import Combine

class ImageFilterMenuView: UIView {
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var okBtn: UIButton!
    
    var filterArray: [ImageFilter]!
    var subscriptions = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let bundle = Bundle.init(for: ImageFilterMenuView.self)
        if let viewsToAdd = bundle.loadNibNamed("ImageFilterMenuView", owner: self, options: nil), let contentView = viewsToAdd.first as? UIView {
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight,
                                            .flexibleWidth]
            
            cancelBtn.addTarget(self, action: #selector(tapCloseBtn), for: .touchUpInside)
        }
    }
    
    @objc func tapCloseBtn( _ sender: AnyObject) {
        self.removeFromSuperview()
    }
}

extension ImageFilterMenuView {
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
    
//    func getTargetViewRect(_ resizeOption: ResizeOption, resizeValue: CGFloat, bottomTrailingPoint: CGPoint) -> CGRect {
//        var resultRect = CGRect(x: 0, y: 0, width: 0, height: 0)
//        var resultWidth: CGFloat = 0
//        var resultHeight: CGFloat = 0
//        var resultOrigin = CGPoint(x: 0, y: 0)
//        var resultSize = CGSize(width: 0, height: 0)
//
//        var scaleFactor: CGFloat = 0
//        var targetLength: CGFloat = 0
//        var changedWidth: CGFloat = 0
//        let lastOuterImgFrame = targetImgView.frame
//        
//        switch resizeOption {
//        case .smaller:
//            changedWidth = lastOuterImgFrame.width - (resizeValue * 2)
//            let minLength = targetImgSize.width * 0.25
//
//            if changedWidth > minLength {
//                targetLength = changedWidth
//            } else {
//                print("too small!")
//                targetLength = minLength
//            }
//                        
//        case .bigger:
//            changedWidth = lastOuterImgFrame.width + (resizeValue * 2)
//            let maxLength = UIScreen.main.bounds.width * 0.75
//            
//            if changedWidth > maxLength {
//                print("too big!")
//                targetLength = maxLength
//            } else {
//                targetLength = changedWidth
//            }
//            
//        default:
//            break
//        }
//
//        scaleFactor = targetLength / targetImgRatio
//
//        resultWidth = targetImgSize.width * scaleFactor
//        resultHeight = targetImgSize.height * scaleFactor
//        
//        resultSize = CGSize(width: resultWidth, height: resultHeight)
//        
//        resultOrigin = CGPoint(x: bottomTrailingPoint.x - resultWidth + 5,
//                               y: bottomTrailingPoint.y - resultHeight + 5)
//        
//        resultRect = CGRect(origin: resultOrigin, size: resultSize)
//        
//        return resultRect
//    }
}
