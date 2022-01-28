import HaishinKit
import AVFoundation
import VideoToolbox
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = StreamingViewModel()
    private var lfView: MTHKSwiftUiView!
    
    init() {
        viewModel.config()
        lfView = MTHKSwiftUiView(rtmpStream: $viewModel.rtmpStream)
    }
    
    var body: some View {
        ZStack {
            lfView
            Button("publish") {
                self.viewModel.publish()
            }
        }
        .ignoresSafeArea()
        .onAppear {
           
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

