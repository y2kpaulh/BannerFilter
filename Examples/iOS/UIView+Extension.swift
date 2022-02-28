//
//  UIView+Extension.swift
//  ShallWeShop
//
//  Created by Inpyo Hong on 2020/02/27.
//  Copyright © 2020 Epiens Corp. All rights reserved.
//

import UIKit

// MARK: - CALayer
extension UIView {
  @IBInspectable var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }

  @IBInspectable var borderColor: UIColor? {
    get {
      guard let color = layer.borderColor else { return nil }
      return UIColor(cgColor: color)
    }
    set {
      layer.borderColor = newValue?.cgColor
    }
  }

  @IBInspectable var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
      layer.masksToBounds = newValue > 0
    }
  }

  @IBInspectable var isCircular: Bool {
    get {
      let radius = self.frame.width/2
      return layer.cornerRadius == radius
    }
    set {
      if newValue {
        let radius = self.frame.width/2
        layer.cornerRadius = radius
      } else {
        layer.cornerRadius = 0
      }

      layer.masksToBounds = newValue
    }
  }
}

// MARK: - Reusable & Nib Loadable
protocol ReusableView: AnyObject {}

extension ReusableView where Self: UIView {
  static var reuseIdentifier: String {
    return String(describing: self)
  }
}

protocol NibLoadableView: AnyObject {}

extension NibLoadableView where Self: UIView {
  static var nibName: String {
    return String(describing: self)
  }
}

// MARK: - Generates instance of view from nib
extension UIView {
  class func instance(_ name: String? = nil, owner: Any? = nil, options: [UINib.OptionsKey: Any]? = nil) -> Self? {
    return instanceHelper(name ?? String(describing: self),
                          owner: owner,
                          options: options)
  }

  fileprivate class func instanceHelper<T>(_ name: String, owner: Any?, options: [UINib.OptionsKey: Any]? = nil) -> T? {
    guard let views = Bundle.main.loadNibNamed(name, owner: owner, options: options) else { return nil }
    return views.first as? T
  }
}

// MARK: - Animation
extension UIView {
//  func setHidden(_ hidden: Bool, animated: Bool) {
//    if isHidden == hidden { return }
//
//    alpha = hidden ? 1 : 0
//    isHidden = false
//
//    UIView.animate(
//      withDuration: animated ? Config.Animations.duration : 0,
//      animations: { [weak self] in
//        guard let self = self else { return }
//        self.alpha = hidden ? 0 : 1
//      },
//      completion: { [weak self] _ in
//        guard let self = self else { return }
//        self.isHidden = hidden
//        self.alpha = 1
//      }
//    )
//  }

  func blink() {
    UIView.animate(withDuration: 1,
                   delay: 0,
                   options: [.curveEaseInOut, .repeat, .autoreverse],
                   animations: { [unowned self] in self.alpha = 0 },
                   completion: { [unowned self] _ in self.alpha = 1 })
  }

  func stopBlink() {
    UIView.animate(withDuration: 0,
                   delay: 0,
                   options: [.curveEaseInOut, .beginFromCurrentState],
                   animations: { [unowned self] in self.alpha = 1.0 })
  }
}

extension UIView {
  var responder: UIViewController? {
    if let next = next as? UIViewController {
      return next
    } else if let next = next as? UIView {
      return next.responder
    } else {
      return nil
    }
  }
}

extension UIView {

  func constrainCentered(_ subview: UIView) {

    subview.translatesAutoresizingMaskIntoConstraints = false

    let verticalContraint = NSLayoutConstraint(
      item: subview,
      attribute: .centerY,
      relatedBy: .equal,
      toItem: self,
      attribute: .centerY,
      multiplier: 1.0,
      constant: 0)

    let horizontalContraint = NSLayoutConstraint(
      item: subview,
      attribute: .centerX,
      relatedBy: .equal,
      toItem: self,
      attribute: .centerX,
      multiplier: 1.0,
      constant: 0)

    let heightContraint = NSLayoutConstraint(
      item: subview,
      attribute: .height,
      relatedBy: .equal,
      toItem: nil,
      attribute: .notAnAttribute,
      multiplier: 1.0,
      constant: subview.frame.height)

    let widthContraint = NSLayoutConstraint(
      item: subview,
      attribute: .width,
      relatedBy: .equal,
      toItem: nil,
      attribute: .notAnAttribute,
      multiplier: 1.0,
      constant: subview.frame.width)

    addConstraints([
                    horizontalContraint,
                    verticalContraint,
                    heightContraint,
                    widthContraint])

  }

  func constrainToEdges(_ subview: UIView) {

    subview.translatesAutoresizingMaskIntoConstraints = false

    let topContraint = NSLayoutConstraint(
      item: subview,
      attribute: .top,
      relatedBy: .equal,
      toItem: self,
      attribute: .top,
      multiplier: 1.0,
      constant: 0)

    let bottomConstraint = NSLayoutConstraint(
      item: subview,
      attribute: .bottom,
      relatedBy: .equal,
      toItem: self,
      attribute: .bottom,
      multiplier: 1.0,
      constant: 0)

    let leadingContraint = NSLayoutConstraint(
      item: subview,
      attribute: .leading,
      relatedBy: .equal,
      toItem: self,
      attribute: .leading,
      multiplier: 1.0,
      constant: 0)

    let trailingContraint = NSLayoutConstraint(
      item: subview,
      attribute: .trailing,
      relatedBy: .equal,
      toItem: self,
      attribute: .trailing,
      multiplier: 1.0,
      constant: 0)

    addConstraints([
                    topContraint,
                    bottomConstraint,
                    leadingContraint,
                    trailingContraint])
  }

}

extension UIView {

  /** Adds Constraints in Visual Formate Language. It is a helper method defined in extensions for convinience usage

   - Parameter format: string formate as we give in visual formate, but view placeholders are like v0,v1, etc
   - Parameter views: It is a variadic Parameter, so pass the sub-views with "," seperated.
   */
  func addConstraintsWithVisualStrings(format: String, views: UIView...) {

    var viewsDictionary = [String: UIView]()

    for (index, view) in views.enumerated() {
      let key = "v\(index)"
      view.translatesAutoresizingMaskIntoConstraints = false
      viewsDictionary[key] = view
    }

    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
  }

  /** This method binds the view with frame of keyboard frame. So, The View will change its frame with the height of the keyboard's height */
  func bindToTheKeyboard(_ bottomConstaint: NSLayoutConstraint? = nil) {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: bottomConstaint)
  }

  @objc func keyboardWillChange(_ notification: NSNotification) {

    let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
    let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
    let curveframe = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
    let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

    let deltaY = targetFrame.origin.y - curveframe.origin.y

    if let constraint = notification.object as? NSLayoutConstraint {
      constraint.constant = deltaY
      UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions.init(rawValue: curve), animations: {
        self.layoutIfNeeded()
      }, completion: nil)

    } else {
      UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions.init(rawValue: curve), animations: {
        self.frame.origin.y += deltaY
      }, completion: nil)
    }
  }
}

extension UIView {
  @discardableResult
  func constrain(constraints: (UIView) -> [NSLayoutConstraint]) -> [NSLayoutConstraint] {
    let constraints = constraints(self)
    self.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate(constraints)
    return constraints
  }

  @discardableResult
  func constrainToEdges(_ inset: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
    return constrain {[
      $0.topAnchor.constraint(equalTo: $0.superview!.topAnchor, constant: inset.top),
      $0.leadingAnchor.constraint(equalTo: $0.superview!.leadingAnchor, constant: inset.left),
      $0.bottomAnchor.constraint(equalTo: $0.superview!.bottomAnchor, constant: inset.bottom),
      $0.trailingAnchor.constraint(equalTo: $0.superview!.trailingAnchor, constant: inset.right)
    ]
    }
  }
}

extension UIView {
  func asImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { rendererContext in
      layer.render(in: rendererContext.cgContext)
    }
  }
}

extension UIView {
  func addShadowView(width: CGFloat=0.2, height: CGFloat=0.2, Opacidade: Float=0.7, maskToBounds: Bool=false, radius: CGFloat=0.5) {
    self.layer.shadowColor = UIColor.black.cgColor
    self.layer.shadowOffset = CGSize(width: width, height: height)
    self.layer.shadowRadius = radius
    self.layer.shadowOpacity = Opacidade
    self.layer.masksToBounds = maskToBounds
  }
}

extension UIView {
  func toImage() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
    self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
    let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return snapshotImageFromMyView!
  }
}

extension UIView {
  func toCIImage() -> CIImage? {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
    self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
    let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    guard let ciimage = CIImage(image: snapshotImageFromMyView!) else { return nil}

    return ciimage
  }
}

extension UIView {
  func roundCorners(corners: UIRectCorner, radius: CGFloat) {
    if #available(iOS 11, *) {
      self.clipsToBounds = true
      self.layer.cornerRadius = radius
      var masked = CACornerMask()
      if corners.contains(.topLeft) { masked.insert(.layerMinXMinYCorner) }
      if corners.contains(.topRight) { masked.insert(.layerMaxXMinYCorner) }
      if corners.contains(.bottomLeft) { masked.insert(.layerMinXMaxYCorner) }
      if corners.contains(.bottomRight) { masked.insert(.layerMaxXMaxYCorner) }
      self.layer.maskedCorners = masked
    } else {
      let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
      let mask = CAShapeLayer()
      mask.path = path.cgPath
      layer.mask = mask
    }
  }
}

extension UIView {
  func pushTransition(_ duration: CFTimeInterval) {
    let animation: CATransition = CATransition()
    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
    animation.type = CATransitionType.push
    animation.subtype = CATransitionSubtype.fromTop
    animation.duration = duration
    layer.add(animation, forKey: CATransitionType.push.rawValue)
  }
}
extension UIView {
  func fadeIn(duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(_: Bool) -> Void in}) {
    UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
      self.alpha = 1.0
    }, completion: completion)  }

  func fadeOut(duration: TimeInterval = 1.0, delay: TimeInterval = 3.0, completion: @escaping (Bool) -> Void = {(_: Bool) -> Void in}) {
    UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
      self.alpha = 0.0
    }, completion: completion)
  }
}
