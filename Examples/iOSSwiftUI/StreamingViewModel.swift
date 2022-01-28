//
//  StreamingViewModel.swift
//  Example iOS
//
//  Created by Inpyo Hong on 2022/01/05.
//  Copyright © 2022 Shogo Endo. All rights reserved.
//

import HaishinKit
import AVFoundation
import VideoToolbox
import SwiftUI
import PhotosUI
final class StreamingViewModel: ObservableObject {
    let maxRetryCount: Int = 5
    private var rtmpConnection = RTMPConnection()
    @Published var rtmpStream: RTMPStream!
    private var sharedObject: RTMPSharedObject!
    private var currentEffect: VideoEffect?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    
    func config() {
        rtmpStream = RTMPStream(connection: rtmpConnection)
        if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
            rtmpStream.orientation = orientation
        }
        rtmpStream.captureSettings = [
            .sessionPreset: AVCaptureSession.Preset.hd1280x720,
            .continuousAutofocus: true,
            .continuousExposure: true
            // .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        rtmpStream.videoSettings = [
            .width: 720,
            .height: 1280
        ]
        //rtmpStream.mixer.recorder.delegate = ExampleRecorderDelegate.shared
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        let requiredAccessLevel: PHAccessLevel = .readWrite
        PHPhotoLibrary.requestAuthorization(for: requiredAccessLevel) { authorizationStatus in
            switch authorizationStatus {
            case .limited:
                print("limited authorization granted")
            case .authorized:
                print("authorization granted")
            default:
                //FIXME: Implement handling for all authorizationStatus
                print("Unimplemented")
                
            }
        }
        
        self.rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print(error.description)
        }
        self.rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { error in
            print(error.description)
        }
        
//        rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
//        lfView?.attachStream(rtmpStream)
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruptionNotification(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRouteChangeNotification(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    func loadDevice() {
        
    }
    
    func publish() {
        UIApplication.shared.isIdleTimerDisabled = true
        print(Preference.defaultInstance.uri!)
        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.connect(Preference.defaultInstance.uri!)
    }
    
    @objc
    private func didInterruptionNotification(_ notification: Notification) {
        print(notification)
    }
    
    @objc
    private func didRouteChangeNotification(_ notification: Notification) {
        print(notification)
    }
    
    @objc
    private func on(_ notification: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        rtmpStream.orientation = orientation
    }
    
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//        if Thread.isMainThread {
//            //currentFPSLabel?.text = "\(rtmpStream.currentFPS)"
//        }
//    }
    
    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
       print(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream.publish(Preference.defaultInstance.streamName!)
            // sharedObject!.connect(rtmpConnection)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard retryCount <= maxRetryCount else {
                return
            }
            Thread.sleep(forTimeInterval: pow(2.0, Double(retryCount)))
            rtmpConnection.connect(Preference.defaultInstance.uri!)
            retryCount += 1
        default:
            break
        }
    }
    
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        print(notification)
        rtmpConnection.connect(Preference.defaultInstance.uri!)
    }
}
