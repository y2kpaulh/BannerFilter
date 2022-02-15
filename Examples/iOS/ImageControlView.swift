//
//  ImageFilterControlView.swift
//  IOSDragViewsGesturesTutorial
//
//  Created by Arthur Knopper on 11/02/2019.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit
import Combine

class ImageFilterControlView: UIView {
    var lastLocation = CGPoint(x: 0, y: 0)
    var lastFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var lastDegrees: Double?
    var closeBtn: UIButton!
    var frameView: UIView!
    
    var gestureEvent = PassthroughSubject<(CGRect,Double?), Never>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        
        lastFrame = frame
        
        // Initialization code
        let panRecognizer = UIPanGestureRecognizer(target:self, action:#selector(detectPan))
        let tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(detectTap))
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(detectRotation))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(detectPinch))
        
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 1
        
        tapRecognizer.delegate = self
        
        rotateRecognizer.delegate = self
        rotateRecognizer.rotation = 0
        
        pinchRecognizer.delegate = self
        pinchRecognizer.scale = 1
        
        self.gestureRecognizers = [tapRecognizer, panRecognizer, pinchRecognizer, rotateRecognizer]
        panRecognizer.require(toFail: tapRecognizer)
        pinchRecognizer.require(toFail: rotateRecognizer)

        self.backgroundColor = .clear
        
//        self.addDashedBorder()

        self.frameView = UIView(frame: self.bounds)
        self.frameView.layer.borderColor = UIColor.red.cgColor
        self.frameView.layer.borderWidth = 1
        
        self.addSubview(self.frameView)
        let btnFrame = CGSize(width: 20, height: 20)
        closeBtn = UIButton(frame: CGRect(origin: CGPoint(x: self.frame.width-(btnFrame.width/2+2), y: 0-(btnFrame.height/2-2)), size: btnFrame))
        closeBtn.backgroundColor = .gray
        closeBtn.layer.cornerRadius = btnFrame.width/2
        closeBtn.addTarget(self, action: #selector(tapCloseBtn), for: .touchUpInside)
        closeBtn.setImage(UIImage(named: "cancel")!, for: .normal)
        closeBtn.tintColor = .white
        
        self.addSubview(closeBtn)
    }
    
    @objc func tapCloseBtn(_sender: UIButton) {
        print(#function)
        print("Checked!")
        UIView.animate(withDuration: 0.5) {
            self.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func detectPan(_ gesture: UIPanGestureRecognizer) {
        print(#function)
        let translation  = gesture.translation(in: self.superview)
        guard let gestureView = gesture.view else {
          return
        }
        
        gestureView.center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
    
        lastFrame = self.frame
        
        gestureEvent.send((lastFrame, nil))
    }
    
    @objc func detectTap(_ gesture: UITapGestureRecognizer) {
        print(#function)
    }
    
    @objc func detectPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let gestureView = gesture.view else {
            return
        }
        
        gestureView.transform = gestureView.transform.scaledBy(
            x: gesture.scale,
            y: gesture.scale
        )
        gesture.scale = 1
        lastFrame = self.frame
        
        gestureEvent.send((lastFrame, nil))
    }
    
    @objc func detectRotation(_ gesture: UIRotationGestureRecognizer) {
        print(#function)
        guard let gestureView = gesture.view else {
            return
        }        
       
        gestureView.transform = gestureView.transform.rotated(
            by: gesture.rotation
        )
        
        let radians: Double = atan2(Double(gestureView.transform.b), Double(gestureView.transform.a))
        let degrees = radians * Double((180 / Float.pi))

        print("degrees", degrees)
        lastDegrees = degrees
        lastFrame = self.frame

        gestureEvent.send((lastFrame, lastDegrees))

        gesture.rotation = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Promote the touched view
        print(#file, #function)
        self.superview?.bringSubviewToFront(self)
        
        // Remember original location
        lastLocation = self.center
    }
}

extension ImageFilterControlView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

extension UIView {
    func addDashedBorder() {
        let color = UIColor.gray.cgColor

        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)

        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [6,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 4).cgPath

        self.layer.addSublayer(shapeLayer)
    }
}
