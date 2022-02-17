//
//  UIImage+Extensions.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/02/17.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import UIKit

extension UIImage {
    struct RotationOptions: OptionSet {
        let rawValue: Int

        static let flipOnVerticalAxis = RotationOptions(rawValue: 1)
        static let flipOnHorizontalAxis = RotationOptions(rawValue: 2)
    }

    func rotated(by rotationAngle: Measurement<UnitAngle>, options: RotationOptions = []) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let rotationInRadians = CGFloat(rotationAngle.converted(to: .radians).value)
        let transform = CGAffineTransform(rotationAngle: rotationInRadians)
        var rect = CGRect(origin: .zero, size: self.size).applying(transform)
        rect.origin = .zero

        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { renderContext in
            renderContext.cgContext.translateBy(x: rect.midX, y: rect.midY)
            renderContext.cgContext.rotate(by: rotationInRadians)

            let x = options.contains(.flipOnVerticalAxis) ? -1.0 : 1.0
            let y = options.contains(.flipOnHorizontalAxis) ? 1.0 : -1.0
            renderContext.cgContext.scaleBy(x: CGFloat(x), y: CGFloat(y))

            let drawRect = CGRect(origin: CGPoint(x: -self.size.width/2, y: -self.size.height/2), size: self.size)
            renderContext.cgContext.draw(cgImage, in: drawRect)
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

extension UIImage {
    func withSize(_ width: CGFloat, _ height: CGFloat) -> UIImage {

      let target = CGSize(width: width, height: height)

      var scaledImageRect = CGRect.zero

      let aspectWidth:CGFloat = target.width / self.size.width
      let aspectHeight:CGFloat = target.height / self.size.height
      let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)

      scaledImageRect.size.width = self.size.width * aspectRatio
      scaledImageRect.size.height = self.size.height * aspectRatio
      scaledImageRect.origin.x = (target.width - scaledImageRect.size.width) / 2.0
      scaledImageRect.origin.y = (target.height - scaledImageRect.size.height) / 2.0

      UIGraphicsBeginImageContextWithOptions(target, false, 0)

      self.draw(in: scaledImageRect)

      let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return scaledImage!
    }

    func rotated(degrees: Double) -> UIImage {

      let radians = CGFloat(Double.pi * degrees / 180)

      var rotatedViewBox: UIView? = UIView(frame: CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
      let t = CGAffineTransform(rotationAngle: radians)
      rotatedViewBox!.transform = t
      let rotatedSize = rotatedViewBox!.frame.size
      rotatedViewBox = nil

      // Create the bitmap context
      UIGraphicsBeginImageContext(rotatedSize)
      let bitmap = UIGraphicsGetCurrentContext()!

      // Move the origin to the middle of the image so we will rotate and scale around the center.
      bitmap.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)

      //   // Rotate the image context
      bitmap.rotate(by: radians)

      // Now, draw the rotated/scaled image into the context
      bitmap.scaleBy(x: 1.0, y: -1.0)
      bitmap.draw(cgImage!, in: CGRect(x:-size.width * scale / 2, y: -size.height * scale / 2, width: size.width * scale, height: size.height * scale))

      let newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()

      return newImage.withSize(newImage.size.width/scale, newImage.size.height/scale)
    }
  }
