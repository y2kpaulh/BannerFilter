//
//  ImageFilterControlView.swift
//  enlargeView
//
//  Created by Inpyo Hong on 2022/02/24.
//

import UIKit
import Combine

class ImageFilterControlView: UIImageView {
    var panGesture = UIPanGestureRecognizer()
    var pinchGesture = UIPinchGestureRecognizer()
    var panEvent = PassthroughSubject<(Int, UIPanGestureRecognizer), Never>()
    var pinchEvent = PassthroughSubject<(Int, UIPinchGestureRecognizer), Never>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureEvent))
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pichGestureEvent))
        pinchGesture.require(toFail: panGesture)
        
        self.gestureRecognizers = [panGesture, pinchGesture]
    }
    
    @objc func panGestureEvent(_ gesture: UIPanGestureRecognizer) {
        self.panEvent.send((self.tag, gesture))
    }
    
    @objc func pichGestureEvent(_ gesture: UIPinchGestureRecognizer) {
        self.pinchEvent.send((self.tag, gesture))
    }
}
