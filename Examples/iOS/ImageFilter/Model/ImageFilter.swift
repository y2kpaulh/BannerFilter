//
//  ImageFilter.swift
//  ImageFilter
//
//  Created by Inpyo Hong on 2022/02/28.
//

import UIKit

struct ImageFilterMenu {
    var controlView: ImageFilterControlView
    var sizeControl: ImageSizeControlView
    var closeButton: ImageControlCloseButton
}

struct ImageFilter {
    var id = Int.random(in: 1...100)
    var rect: CGRect
    var imageArray: [UIImage]
    let info: ImageInfo
}

struct ImageInfo {
    let size: CGSize
    let ratio: CGFloat
}

struct ImageFilterData {
    var menu: ImageFilterMenu
    var filter: ImageFilter
}

