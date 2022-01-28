//
//  MTHKSwiftUiView.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/01/05.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import Foundation
import SwiftUI
import HaishinKit

struct MTHKSwiftUiView: UIViewRepresentable {
    var mthkView = MTHKView(frame: UIScreen.main.bounds)

    @Binding var rtmpStream: RTMPStream
    
    func makeUIView(context: Context) -> MTHKView {
        mthkView.contentMode = .scaleAspectFill
        return mthkView
    }

    func updateUIView(_ uiView: MTHKView, context: Context) {
        mthkView.attachStream(rtmpStream)
    }
}
