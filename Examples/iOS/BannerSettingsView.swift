//
//  BannerSettingsView.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/01/26.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import UIKit
import Combine

class BannerSettingsView: UIView {
    @IBOutlet weak var bannerPosition: UISegmentedControl!
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
    @IBOutlet weak var applyBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var layerImageView: UIImageView!
    @IBOutlet weak var photosBtn: UIButton!
    
    var imageArray = [UIImage]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                guard self.imageArray.count > 0 else { return }
                self.layerImageView.image = self.imageArray[0]
                
                if self.isSelectedLayer {
                    self.applyBtn.isEnabled = true
                } else {
                    self.applyBtn.isEnabled = false
                }
            }
        }
    }
    
    var buttonDataArray = [BannerData]()
    var bannerLayerEvent = PassthroughSubject<[BannerLayer], Never>()
    var marginPoint: CGPoint = CGPoint(x: 0, y: 0)
    var bannerLayer: [BannerLayer]!
    
    var isSelectedLayer: Bool {
        get {
            let selectedBtnArray = self.buttonDataArray.filter {
                $0.button.isSelected == true
            }
            
            if selectedBtnArray.count > 0, self.imageArray.count > 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    init(frame: CGRect, bannerLayer: [BannerLayer]) {
        super.init(frame: frame)
        self.bannerLayer = bannerLayer
        commonInit()
    }
    
    func commonInit() {
        let bundle = Bundle.init(for: BannerSettingsView.self)
        if let viewsToAdd = bundle.loadNibNamed("BannerSettingsView", owner: self, options: nil), let contentView = viewsToAdd.first as? UIView {
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight,
                                            .flexibleWidth]
        }
        
        xAxisMargin.text = String(Int(xAxisSlider.value))
        yAxisMargin.text = String(Int(yAxisSlider.value))
        
        buttonDataArray = [BannerData(align: .topLeft, button: topLeftBtn),
                           BannerData(align: .topMid, button: topMidBtn),
                           BannerData(align: .topRight, button: topRightBtn),
                           BannerData(align: .midLeft, button: midLeftBtn),
                           BannerData(align: .midRight, button: midRightBtn),
                           BannerData(align: .bottomLeft, button: bottomLeftBtn),
                           BannerData(align: .bottomMid, button: bottomMidBtn),
                           BannerData(align: .bottomRight, button: bottomRightBtn)]
        
        if let align = bannerLayer[BannerLayerPosition.bottom.rawValue].position.align, let margin = bannerLayer[BannerLayerPosition.bottom.rawValue].position.margin, let imageArray = bannerLayer[BannerLayerPosition.bottom.rawValue].imageArray {
            let pos = BannerAlign(rawValue: align.rawValue)!
            
            self.imageArray = imageArray
            
            buttonDataArray = buttonDataArray.map {
                let btnData = $0
                btnData.button.isSelected = btnData.align == pos ? true : false
                return btnData
            }
            
            xAxisSlider.value = Float(margin.x)
            yAxisSlider.value = Float(margin.y)
            xAxisMargin.text = String(Int(margin.x))
            yAxisMargin.text = String(Int(margin.y))
            
            deleteBtn.isHidden = false
        }
    }
    
    @IBAction func tapBannerBtn(_ sender: Any) {
        let btn = sender as! UIButton
        print(btn.tag)
        
        let pos = BannerAlign(rawValue: btn.tag)!
        
        buttonDataArray = buttonDataArray.map {
            let btnData = $0
            btnData.button.isSelected = btnData.align == pos ? true : false
            return btnData
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isSelectedLayer {
                self.applyBtn.isEnabled = true

            } else {
                self.applyBtn.isEnabled = false
            }
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
    
    @IBAction func selectLayer(_ sender: Any) {
        print(#function, BannerLayerPosition(rawValue: self.bannerPosition.selectedSegmentIndex)!)
        
        let layerIndex = self.bannerPosition.selectedSegmentIndex
        
        if let align = bannerLayer[layerIndex].position.align, let margin = bannerLayer[layerIndex].position.margin, let imageArray = bannerLayer[layerIndex].imageArray {
            let pos = BannerAlign(rawValue: align.rawValue)!
            self.imageArray = imageArray
            
            buttonDataArray = buttonDataArray.map {
                let btnData = $0
                btnData.button.isSelected = btnData.align == pos ? true : false
                return btnData
            }
            
            xAxisSlider.value = Float(margin.x)
            yAxisSlider.value = Float(margin.y)
            xAxisMargin.text = String(Int(margin.x))
            yAxisMargin.text = String(Int(margin.y))
            
            applyBtn.isEnabled = true
            deleteBtn.isHidden = false
        } else {
            buttonDataArray = buttonDataArray.map {
                let btnData = $0
                btnData.button.isSelected = false
                return btnData
            }
            
            imageArray = []
            
            xAxisSlider.value = Float(0)
            yAxisSlider.value = Float(0)
            xAxisMargin.text = String(Int(0))
            yAxisMargin.text = String(Int(0))
            
            applyBtn.isEnabled = false
            deleteBtn.isHidden = true
            layerImageView.image = nil
        }
    }
    
    @IBAction func tapApplyBtn(_ sender: Any) {
        let selectedBtnArray = buttonDataArray.filter {
            $0.button.isSelected == true
        }
        
        if selectedBtnArray.count > 0, self.imageArray.count > 0 {
            self.bannerLayer[self.bannerPosition.selectedSegmentIndex] = BannerLayer(position: BannerPosition(layer: BannerLayerPosition(rawValue: self.bannerPosition.selectedSegmentIndex)!,align: selectedBtnArray[0].align,margin: marginPoint), imageArray: self.imageArray)
            
            self.bannerLayerEvent.send(self.bannerLayer)
        }
        else {
            print("not selected position")
        }
    }
    
    @IBAction func tapDeleteBtn(_ sender: Any) {
        self.bannerLayer[self.bannerPosition.selectedSegmentIndex] = BannerLayer(position: BannerPosition(layer: BannerLayerPosition(rawValue: self.bannerPosition.selectedSegmentIndex)!,
                                             align: nil,
                                             margin: nil), imageArray: nil)

        self.bannerLayerEvent.send(self.bannerLayer)
    }
}
