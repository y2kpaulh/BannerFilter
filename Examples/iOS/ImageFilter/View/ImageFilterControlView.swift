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
    
    var panEvent = PassthroughSubject<(Int, CGRect), Never>()
    var pinchEvent = PassthroughSubject<(Int, CGRect), Never>()
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
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
        
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureEvent))
        tapGesture.require(toFail: tapGesture)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureEvent))
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pichGestureEvent))

        self.gestureRecognizers = [tapGesture, panGesture, pinchGesture]
    }
    
    @objc func tapGestureEvent(_ sender: UITapGestureRecognizer) {
        print(#function)
        self.tapEvent.send(self.tag)
    }
    
    @objc func panGestureEvent(_ sender: UIPanGestureRecognizer) {
        print(#function)
        let translation = sender.translation(in: self)
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let self = self else { return }
            self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        }
        
        sender.setTranslation(CGPoint.zero, in: self)
        
        self.panEvent.send((self.tag, self.frame))
    }

    @objc func pichGestureEvent(_ sender: UIPinchGestureRecognizer) {
        print(#function)
        guard let gestureView = sender.view else {
          return
        }

        gestureView.transform = gestureView.transform.scaledBy(
          x: sender.scale,
          y: sender.scale
        )
        
        sender.scale = 1
        
        self.pinchEvent.send((self.tag, self.frame))
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
