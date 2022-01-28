import AVFoundation
import HaishinKit
import UIKit

final class PronamaEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
    
    var extent = CGRect.zero {
        didSet {
            if extent == oldValue {
                return
            }
            
            UIGraphicsBeginImageContext(extent.size)
            let image = UIImage(named: "banner13")!.resize(targetSize: CGSize(width: 720, height: 1280))
            image.draw(at: CGPoint(x: 0, y: 0))
            let image2 = UIImage(named: "Icon")!.resize(targetSize: CGSize(width: 80, height: 80))
            image2.draw(at: CGPoint(x: 0, y: 0))
            
            pronama = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
            UIGraphicsEndImageContext()
        }
    }
    var pronama: CIImage?
    var banner: CIImage?
    
    override init() {
        super.init()
    }
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else {
            return image
        }
        extent = image.extent
        filter.setValue(pronama!, forKey: "inputImage")
        filter.setValue(image, forKey: "inputBackgroundImage")
        return filter.outputImage!
    }
}

final class MonochromeEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CIColorMonochrome")
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else {
            return image
        }
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: "inputColor")
        filter.setValue(1.0, forKey: "inputIntensity")
        return filter.outputImage!
    }
}

final class BannerEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
    var banner: CIImage?
    var currIndexArray = [0, 0, 0]
    var bannerLayers: [BannerLayer] = [BannerLayer]()

    var extent = CGRect.zero {
        didSet {
//            if extent == oldValue {
//                return
//            }
            UIGraphicsBeginImageContext(extent.size)
            self.drawLayerImage(currIndexArray: &currIndexArray, extent: extent, layers: bannerLayers)
            banner = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
            UIGraphicsEndImageContext()
        }
    }
    
    override init() {
        super.init()
    }
    
    init(layer: [BannerLayer]) {
        self.bannerLayers = layer
    }
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else {
            return image
        }
        extent = image.extent
        filter.setValue(banner!, forKey: "inputImage")
        filter.setValue(image, forKey: "inputBackgroundImage")
        return filter.outputImage!
    }
    
    func drawLayerImage(currIndexArray: inout [Int], extent: CGRect, layers: [BannerLayer]) {
        for (index, layer) in layers.enumerated() {
            if let imgArr = layer.imageArray, let align = layer.position.align, let margin = layer.position.margin {

                if imgArr.count > 1 {
                    if imgArr.count == currIndexArray[index] + 1 {
                        currIndexArray[index] = 0
                    } else {
                        currIndexArray[index] = currIndexArray[index] + 1
                    }
                }
                
                let image: UIImage = imgArr[currIndexArray[index]]
                
                switch align {
                case .topLeft:
                    image.draw(at: CGPoint(x: margin.x,
                                           y: margin.y))
                    
                case .topMid:
                    image.draw(at: CGPoint(x: (extent.size.width - image.size.width)/2 + margin.x,
                                           y: margin.y))
                    
                case .topRight:
                    image.draw(at: CGPoint(x: (extent.size.width - image.size.width) + margin.x,
                                           y: margin.y))
                    
                case .midLeft:
                    image.draw(at: CGPoint(x: margin.x,
                                           y: (extent.size.height - image.size.height)/2 + margin.y))
                    
                case .midRight:
                    image.draw(at: CGPoint(x: (extent.size.width - image.size.width) + margin.x,
                                           y: (extent.size.height - image.size.height)/2 + margin.y))
                    
                case .bottomLeft:
                    image.draw(at: CGPoint(x: margin.x,
                                           y: (extent.size.height - image.size.height) + margin.y))
                    
                case .bottomMid:
                    image.draw(at: CGPoint(x: (extent.size.width - image.size.width)/2 + margin.x,
                                           y: (extent.size.height - image.size.height) + margin.y))
                    
                case .bottomRight:
                    image.draw(at: CGPoint(x: (extent.size.width - image.size.width) + margin.x,
                                           y: (extent.size.height - image.size.height) + margin.y))
                }
            }
        }
    }
}

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
