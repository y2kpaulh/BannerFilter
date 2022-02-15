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
                
                var image: UIImage = imgArr[currIndex].resize(targetSize: rect.size)
                
                if let degrees = degrees {
                    print("publish degrees image")
                    image = image.imageRotatedByDegrees(degrees: degrees)
                }
                
                image.draw(at:rect.origin)
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

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        let rotatedSize: CGSize = CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width).size

        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()
        return newImage
    }
    
    public func imageRotatedByRadian(radian: CGFloat) -> UIImage {
        let rotatedSize: CGSize = CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width).size

        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: radian)
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()
        return newImage
    }
}
