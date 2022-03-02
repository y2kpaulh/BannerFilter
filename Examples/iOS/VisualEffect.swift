import AVFoundation
import HaishinKit
import UIKit

final class TempBannerEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
    var tmpBanner: CIImage?
    var rect: CGRect!
    var degrees: Double?
    var imageArray: [UIImage]!
    var currIndex = 0
    
    var extent = CGRect.zero {
        didSet {
            UIGraphicsBeginImageContext(extent.size)
            
            if let imgArr = imageArray {
                if imgArr.count > 1 {
                    if imgArr.count == currIndex + 1 {
                        currIndex = 0
                    } else {
                        currIndex = currIndex + 1
                    }
                }
                
                var targetImage: UIImage = imgArr[currIndex]
                
                if let degrees = degrees {
                    targetImage = targetImage.rotated(by: Measurement(value: degrees, unit: .degrees))!
                }
                
                targetImage = targetImage.resize(targetSize: rect.size)
                //targetImage = targetImage.withSize(rect.size.width, rect.size.height)
                
                targetImage.draw(at: rect.origin)
            }
            
            tmpBanner = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
            
            UIGraphicsEndImageContext()
        }
    }
    
    override init() {
        super.init()
    }
    
    init(rect: CGRect, imageArray: [UIImage], degrees: Double? = nil) {
        self.rect = rect
        self.imageArray = imageArray
        self.degrees = degrees
    }
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else {
            return image
        }
        extent = image.extent
        filter.setValue(tmpBanner!, forKey: "inputImage")
        filter.setValue(image, forKey: "inputBackgroundImage")
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


final class ImageFilterEffect: VideoEffect {
    let filter: CIFilter? = CIFilter(name: "CISourceOverCompositing")
    var imageFilter: CIImage?
    var currIndexArray: [Int] = [Int]()
    var filterLayer: [ImageFilter] = [ImageFilter]()
    var layerCount: Int = 0
    
    var extent = CGRect.zero {
        didSet {
            UIGraphicsBeginImageContext(extent.size)
            self.drawLayerImage(currIndexArray: &currIndexArray, layer: filterLayer)
            imageFilter = CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!, options: nil)
            UIGraphicsEndImageContext()
        }
    }
    
    override init() {
        super.init()
    }
    
    init(layer: [ImageFilter]) {
        self.filterLayer = layer
        self.layerCount = self.filterLayer.count
        self.currIndexArray = [Int](repeating: 0, count: self.layerCount)
    }
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        guard let filter: CIFilter = filter else {
            return image
        }
        extent = image.extent
        filter.setValue(imageFilter!, forKey: "inputImage")
        filter.setValue(image, forKey: "inputBackgroundImage")
        return filter.outputImage!
    }
    
    func drawLayerImage(currIndexArray: inout [Int], layer: [ImageFilter]) {
        for (index, layer) in layer.enumerated() {
            if layer.imageArray.count > 1 {
                if layer.imageArray.count == currIndexArray[index] + 1 {
                    currIndexArray[index] = 0
                } else {
                    currIndexArray[index] = currIndexArray[index] + 1
                }
            }
            
            var targetImage: UIImage = layer.imageArray[currIndexArray[index]]
            
            //            if let degrees = layer.degrees {
            //                targetImage = targetImage.rotated(by: Measurement(value: degrees, unit: .degrees))!
            //            }
            
            targetImage = targetImage.resize(targetSize: layer.rect.size)
            
            targetImage.draw(at: layer.rect.origin)
        }
    }
}
