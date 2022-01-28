//
//  BannerPostionViewController.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/01/20.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import UIKit
import Combine

class BannerPostionViewController: UIViewController {
    @IBOutlet weak var topLeftBtn: UIButton!
    @IBOutlet weak var topMidBtn: UIButton!
    @IBOutlet weak var topRightBtn: UIButton!
    @IBOutlet weak var midLeftBtn: UIButton!
    @IBOutlet weak var midRightBtn: UIButton!
    @IBOutlet weak var bottomLeftBtn: UIButton!
    @IBOutlet weak var bottomMidBtn: UIButton!
    @IBOutlet weak var bottomRightBtn: UIButton!
    @IBOutlet weak var xAxisSlider: UISlider!
    @IBOutlet weak var yAxisSlider: UISlider!
    @IBOutlet weak var xAxisMargin: UILabel!
    @IBOutlet weak var yAxisMargin: UILabel!

    var buttonDataArray = [BannerData]()
    
    var selectedBanner = PassthroughSubject<BannerPosition, Never>()

    var marginPoint: CGPoint = CGPoint(x: 0, y: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        xAxisMargin.text = String(Int(xAxisSlider.value))
        yAxisMargin.text = String(Int(yAxisSlider.value))
        
        buttonDataArray = [BannerData(position: .topLeft, button: topLeftBtn),
                           BannerData(position: .topMid, button: topMidBtn),
                           BannerData(position: .topRight, button: topRightBtn),
                           BannerData(position: .midLeft, button: midLeftBtn),
                           BannerData(position: .midRight, button: midRightBtn),
                           BannerData(position: .bottomLeft, button: bottomLeftBtn),
                           BannerData(position: .bottomMid, button: bottomMidBtn),
                           BannerData(position: .bottomRight, button: bottomRightBtn)]
    }
    
    @IBAction func tapBannerBtn(_ sender: Any) {
        let btn = sender as! UIButton
        print(btn.tag)
        
        let pos = BannerAlign(rawValue: btn.tag)!
                        
        buttonDataArray = buttonDataArray.map {
            let btnData = $0
            btnData.button.isSelected = btnData.position == pos ? true : false
            return btnData
        }
    }
    
    @IBAction func tapSlider(_ sender: Any) {
        let slider = sender as! UISlider
        print(slider.tag, slider.value)
        
        switch slider.tag {
        case 0:
            xAxisMargin.text = String(Int(slider.value))
        case 1:
            yAxisMargin.text = String(Int(slider.value))
        default:
            break
        }
        
        marginPoint = CGPoint(x: CGFloat(xAxisSlider.value), y: CGFloat(yAxisSlider.value))
    }
    
    @IBAction func tapCloseBtn(_ sender: Any) {
        let selectedBtnArray = buttonDataArray.filter {
            $0.button.isSelected == true
        }
        
        if selectedBtnArray.count > 0 {
            print(selectedBtnArray[0].position, marginPoint)
            
            self.selectedBanner.send(BannerPosition(layer: BannerLayerPosition(, position: selectedBtnArray[0].position, margin: marginPoint))
            self.dismiss(animated: true)
        }
        else {
            print("not selected position")
        }
    }
}
