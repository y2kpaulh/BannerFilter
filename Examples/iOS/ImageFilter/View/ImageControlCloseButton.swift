//
//  ImageControlCloseButton.swift
//  enlargeView
//
//  Created by Inpyo Hong on 2022/02/24.
//

import UIKit
import Combine

class ImageControlCloseButton: UIButton {
    var closeEvent = PassthroughSubject<Int, Never>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        self.setImage(UIImage(named: "imgClose")!, for: .normal)
        self.backgroundColor = .clear
        
        self.addTarget(self, action: #selector(tapCloseBtn), for: .touchUpInside)
    }
    
    
    @objc func tapCloseBtn(_ sender: AnyObject) {
        self.closeEvent.send(self.tag)
    }

}
