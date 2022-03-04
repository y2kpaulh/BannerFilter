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
    var rotationGesture = UIRotationGestureRecognizer()

    var panEvent = PassthroughSubject<(Int, UIPanGestureRecognizer), Never>()
    var pinchEvent = PassthroughSubject<(Int, UIPinchGestureRecognizer), Never>()
    var rotationEvent = PassthroughSubject<(Int, UIRotationGestureRecognizer), Never>()

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
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotationGestureEvent))
        
        pinchGesture.scale = 1
        rotationGesture.rotation = 0

        self.gestureRecognizers = [panGesture, pinchGesture, rotationGesture]
    }
    
    @objc func panGestureEvent(_ gesture: UIPanGestureRecognizer) {
        self.panEvent.send((self.tag, gesture))
    }
    
    @objc func pichGestureEvent(_ gesture: UIPinchGestureRecognizer) {
        self.pinchEvent.send((self.tag, gesture))
    }
    
    @objc func rotationGestureEvent(_ gesture: UIRotationGestureRecognizer) {
        self.rotationEvent.send((self.tag, gesture))
    }
}
