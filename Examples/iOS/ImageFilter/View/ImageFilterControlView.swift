//
//  ImageFilterControlView.swift
//  enlargeView
//
//  Created by Inpyo Hong on 2022/02/24.
//

import UIKit
import Combine

class ImageFilterControlView: UIImageView {
    var tapGesture = UITapGestureRecognizer()
    var panGesture = UIPanGestureRecognizer()
    var pinchGesture = UIPinchGestureRecognizer()
    
    var panEvent = PassthroughSubject<(Int, UIPanGestureRecognizer), Never>()
    var pinchEvent = PassthroughSubject<(Int, UIPinchGestureRecognizer), Never>()
    var tapEvent = PassthroughSubject<Int, Never>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        self.backgroundColor = .clear
//        self.layer.borderWidth = 1
//        self.layer.borderColor = UIColor.gray.cgColor
        
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureEvent))
        tapGesture.require(toFail: tapGesture)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureEvent))
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pichGestureEvent))
        
        self.gestureRecognizers = [tapGesture, panGesture, pinchGesture]
    }
    
    @objc func tapGestureEvent(_ gesture: UITapGestureRecognizer) {
        self.tapEvent.send(self.tag)
    }
    
    @objc func panGestureEvent(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: self)
//        let velocity = gesture.velocity(in: self)
//        let speedThreshold:CGFloat = 300
//
//        print(self.tag, "velocity", velocity)
//
//        if velocity.x.magnitude > velocity.y.magnitude {
//            //좌우
//            velocity.x < 0 ? print("좌") :  print("우")
//        } else {
//            //상하
//            velocity.y < 0 ? print("상") :  print("하")
//        }
//
//        if velocity.y.magnitude > speedThreshold {
//            // 그냥 지나가는거니까 이미지 렌더 필요 없음
//            print(self.tag, "그냥 지나가는거니까 이미지 렌더 필요 없음")
//        } else {
//            //그냥 지나가는게 아니니까 이미지 렌더 필요
//            print(self.tag, "그냥 지나가는게 아니니까 이미지 렌더 필요")
//        }
        
        self.panEvent.send((self.tag, gesture))
    }
    
    @objc func pichGestureEvent(_ gesture: UIPinchGestureRecognizer) {
        self.pinchEvent.send((self.tag, gesture))
    }
}
