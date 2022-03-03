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
    
    var tapGesture = UITapGestureRecognizer()
    var filterArray: [ImageFilter]!
    var subscriptions = Set<AnyCancellable>()
    var tapEvent = PassthroughSubject<CGPoint, Never>()

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
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureEvent))
            self.gestureRecognizers = [tapGesture]
            self.isUserInteractionEnabled = true
        }
    }
    
    @objc func tapGestureEvent(_ gesture: UITapGestureRecognizer) {
        guard let gestureView = gesture.view else {
            return
        }
        
        let touchPoint: CGPoint = gesture.location(in: gestureView)
        print("touchPoint", touchPoint)
        self.tapEvent.send(touchPoint)
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
}
