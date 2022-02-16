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

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
