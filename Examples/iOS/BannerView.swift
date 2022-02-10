//
//  BannerView.swift
//  IOSDragViewsGesturesTutorial
//
//  Created by Arthur Knopper on 11/02/2019.
//  Copyright © 2019 Arthur Knopper. All rights reserved.
//

import UIKit

class BannerView: UIView {
    var lastLocation = CGPoint(x: 0, y: 0)
    var lastRotation: CGFloat = 0
    
    init(frame: CGRect, image: UIImage) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
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
        
        self.gestureRecognizers = [tapRecognizer, panRecognizer, rotateRecognizer, pinchRecognizer]
        panRecognizer.require(toFail: tapRecognizer)
        
        self.backgroundColor = UIColor.black
        
        let imgView = UIImageView(image: image)
        imgView.frame = self.bounds
        self.addSubview(imgView)
        
        self.addDashedBorder()
        
        let btnFrame = CGSize(width: 30, height: 30)
        let closeBtn = UIButton(frame: CGRect(origin: CGPoint(x: self.frame.width-(btnFrame.width/2+2), y: 0-(btnFrame.height/2-2)), size: btnFrame))
        closeBtn.backgroundColor = .gray
        closeBtn.layer.cornerRadius = btnFrame.width/2
        closeBtn.addTarget(self, action: #selector(tapCloseBtn), for: .touchUpInside)
        closeBtn.setTitle("X", for: .normal)
        closeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        
        self.addSubview(closeBtn)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        self.center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
    }
    
    @objc func detectTap(_ gesture: UITapGestureRecognizer) {
        print(#function)
        UIView.animate(withDuration: 0.5) {
            self.removeFromSuperview()
        }
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
    }
    
    
    @objc func detectRotation(_ gesture: UIRotationGestureRecognizer) {
        print(#function)
        guard let gestureView = gesture.view else {
            return
        }
        
        gestureView.transform = gestureView.transform.rotated(
            by: gesture.rotation
        )
        gesture.rotation = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Promote the touched view
        self.superview?.bringSubviewToFront(self)
        
        // Remember original location
        lastLocation = self.center
    }
}

extension BannerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
