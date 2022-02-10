import AVFoundation
import HaishinKit
import Photos
import UIKit
import VideoToolbox
import PhotosUI
import Combine

enum BannerAlign: Int, CaseIterable {
    case topLeft = 0,
         topMid,
         topRight,
         midLeft,
         midRight,
         bottomLeft,
         bottomMid,
         bottomRight
}

struct BannerData {
    var align: BannerAlign
    var button: UIButton
}

enum BannerLayerPosition: Int, CaseIterable {
    case bottom = 0, mid, top
}

struct BannerPosition {
    var layer: BannerLayerPosition
    var align: BannerAlign? = nil
    var margin: CGPoint? = nil
}

struct BannerLayer {
    var position: BannerPosition
    var imageArray: [UIImage]? = nil
}

final class ExampleRecorderDelegate: DefaultAVRecorderDelegate {
    static let `default` = ExampleRecorderDelegate()
    
    override func didFinishWriting(_ recorder: AVRecorder) {
        guard let writer: AVAssetWriter = recorder.writer else {
            return
        }
        PHPhotoLibrary.shared().performChanges({() -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: writer.outputURL)
        }, completionHandler: { _, error -> Void in
            do {
                try FileManager.default.removeItem(at: writer.outputURL)
            } catch {
                print(error)
            }
        })
    }
}

final class LiveViewController: UIViewController {
    private static let maxRetryCount: Int = 5
    var screenRatio: CGSize {
        return CGSize(width: self.currentResolution.width/UIScreen.main.bounds.width, height: self.currentResolution.height/UIScreen.main.bounds.height)
    }
    @IBOutlet private weak var lfView: MTHKView!
    @IBOutlet private weak var currentFPSLabel: UILabel!
    @IBOutlet private weak var publishButton: UIButton!
    @IBOutlet private weak var pauseButton: UIButton!
    @IBOutlet private weak var videoBitrateLabel: UILabel!
    @IBOutlet private weak var videoBitrateSlider: UISlider!
    @IBOutlet private weak var audioBitrateLabel: UILabel!
    @IBOutlet private weak var zoomSlider: UISlider!
    @IBOutlet private weak var audioBitrateSlider: UISlider!
    @IBOutlet private weak var fpsControl: UISegmentedControl!
    @IBOutlet private weak var effectSegmentControl: UISegmentedControl!
    
    private var rtmpConnection = RTMPConnection()
    private var rtmpStream: RTMPStream!
    private var sharedObject: RTMPSharedObject!
    private var currentEffect: VideoEffect?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    
    private var currentResolution: CGSize = CGSize(width: 720, height: 1280)
    private var subscriptions = Set<AnyCancellable>()
    
    private var bannerSettingsView: BannerSettingsView!
    
    var bannerLayer: [BannerLayer] = [BannerLayer(position: BannerPosition(layer: .bottom)),
                                      BannerLayer(position: BannerPosition(layer: .mid)),
                                      BannerLayer(position: BannerPosition(layer: .top))]

    override func viewDidLoad() {
        super.viewDidLoad()
        print("UIScreen.main.bounds: \(UIScreen.main.bounds)")
        
        rtmpStream = RTMPStream(connection: rtmpConnection)
        if let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) {
            rtmpStream.orientation = orientation
        }
        
        rtmpStream.captureSettings = [
            .sessionPreset: AVCaptureSession.Preset.hd1280x720,
            .continuousAutofocus: true,
            .continuousExposure: true,
            .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
        ]
        rtmpStream.videoSettings = [
            .width: currentResolution.width,
            .height: currentResolution.height,
            .profileLevel: kVTProfileLevel_H264_High_AutoLevel
        ]
        //rtmpStream.mixer.recorder.delegate = ExampleRecorderDelegate.shared
        
        videoBitrateSlider?.value = Float(RTMPStream.defaultVideoBitrate) / 1000
        audioBitrateSlider?.value = Float(RTMPStream.defaultAudioBitrate) / 1000
                
        //lfView.videoGravity = .resizeAspectFill
        lfView.isUserInteractionEnabled = true

        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapScreen(_:)))
        let panRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panScreen(_:)))
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 1
        
        lfView.gestureRecognizers = [panRecognizer, tapRecognizer]
        panRecognizer.require(toFail: tapRecognizer)
        
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
    }
    
    @objc func tapPhotosBtn(_ sender: Any) {
       selectBanner()
    }
    
    @objc func tapCloseBtn(_ sender: Any) {
        self.bannerSettingsView.removeFromSuperview()
    }
    
    @objc func panScreen(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: view)

        guard let gestureView = gesture.view else {
            return
        }
        
        let touchPoint: CGPoint = gesture.location(in: gestureView)
        let pointOfInterest = CGPoint(x: touchPoint.x / gestureView.bounds.size.width, y: touchPoint.y / gestureView.bounds.size.height)
        
        let realPoint = CGPoint(x: currentResolution.width * pointOfInterest.x, y: currentResolution.height * pointOfInterest.y)

        print("gesture.view", gestureView.bounds.size, "touchPoint: \(touchPoint), pointOfInterest: \(pointOfInterest), realPoint: \(realPoint)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let currentEffect: VideoEffect = self.currentEffect {
                _ = self.rtmpStream.unregisterVideoEffect(currentEffect)
            }
            self.currentEffect = PronamaEffect(point: realPoint)
            _ = self.rtmpStream.registerVideoEffect(self.currentEffect!)
        }
    }
    
    @objc func tapScreen(_ gesture: UIGestureRecognizer) {
        print(#function)
        
        if let currentEffect: VideoEffect = self.currentEffect {
            _ = self.rtmpStream.unregisterVideoEffect(currentEffect)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        logger.info("viewWillAppear")
        super.viewWillAppear(animated)
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            logger.warn(error.description)
        }
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentPosition)) { error in
            logger.warn(error.description)
        }
        rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)
        lfView?.attachStream(rtmpStream)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruptionNotification(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRouteChangeNotification(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        logger.info("viewWillDisappear")
        super.viewWillDisappear(animated)
        rtmpStream.removeObserver(self, forKeyPath: "currentFPS")
        rtmpStream.close()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func rotateCamera(_ sender: UIButton) {
        logger.info("rotateCamera")
        let position: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        rtmpStream.captureSettings[.isVideoMirrored] = position == .front
        rtmpStream.attachCamera(DeviceUtil.device(withPosition: position)) { error in
            logger.warn(error.description)
        }
        currentPosition = position
    }
    
    @IBAction func toggleTorch(_ sender: UIButton) {
        rtmpStream.torch.toggle()
    }
    
    @IBAction func on(slider: UISlider) {
        if slider == audioBitrateSlider {
            audioBitrateLabel?.text = "audio \(Int(slider.value))/kbps"
            rtmpStream.audioSettings[.bitrate] = slider.value * 1000
        }
        if slider == videoBitrateSlider {
            videoBitrateLabel?.text = "video \(Int(slider.value))/kbps"
            rtmpStream.videoSettings[.bitrate] = slider.value * 1000
        }
        if slider == zoomSlider {
            rtmpStream.setZoomFactor(CGFloat(slider.value), ramping: true, withRate: 5.0)
        }
    }
    
    @IBAction func on(pause: UIButton) {
        rtmpStream.paused.toggle()
    }
    
    @IBAction func on(close: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func on(publish: UIButton) {
        if publish.isSelected {
            UIApplication.shared.isIdleTimerDisabled = false
            rtmpConnection.close()
            rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            publish.setTitle("●", for: [])
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
            rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            rtmpConnection.connect(Preference.defaultInstance.uri!)
            publish.setTitle("■", for: [])
        }
        publish.isSelected.toggle()
    }
    
    @IBAction func buttonDidTap(_ sender: Any) {
        //selectBanner()
        self.bannerPositionMenu()
    }
    
    func bannerPositionMenu() {
        self.bannerSettingsView = BannerSettingsView(frame: CGRect(x: 0, y: 0, width: 300, height: 500), bannerLayer:  self.bannerLayer)
        
        self.bannerSettingsView.bannerLayerEvent
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.bannerSettingsView.removeFromSuperview()
                self.bannerLayer = $0
                
                if let currentEffect: VideoEffect = self.currentEffect {
                    _ =  self.rtmpStream.unregisterVideoEffect(currentEffect)
                }

                currentEffect = BannerEffect(layer: self.bannerLayer)
                _ = rtmpStream.registerVideoEffect(currentEffect!)
            }
            .store(in: &subscriptions)
        
        self.bannerSettingsView.closeBtn.addTarget(self, action: #selector(tapCloseBtn(_:)), for: .touchUpInside)
        self.bannerSettingsView.photosBtn.addTarget(self, action: #selector(tapPhotosBtn(_:)), for: .touchUpInside)
        self.bannerSettingsView.center = self.view.center
        self.view.addSubview(self.bannerSettingsView)
    }
    
    func selectBanner() {
        let accessLevel: PHAccessLevel = .readWrite
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: accessLevel)
        
        switch authorizationStatus {
        case .authorized:
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .any(of: [.images])
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
            
        case .limited:
            print("limited authorization granted")
        default:
            //FIXME: Implement handling for all authorizationStatus values
            print("Not implemented")
        }
    }
    
    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        logger.info(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            retryCount = 0
            rtmpStream.publish(Preference.defaultInstance.streamName!)
            // sharedObject!.connect(rtmpConnection)
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            guard retryCount <= LiveViewController.maxRetryCount else {
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
        logger.error(notification)
        rtmpConnection.connect(Preference.defaultInstance.uri!)
    }
    
    @IBAction private func onFPSValueChanged(_ segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            rtmpStream.captureSettings[.fps] = 15.0
        case 1:
            rtmpStream.captureSettings[.fps] = 30.0
        case 2:
            rtmpStream.captureSettings[.fps] = 60.0
        default:
            break
        }
    }
    
    @IBAction private func onEffectValueChanged(_ segment: UISegmentedControl) {
        if let currentEffect: VideoEffect = currentEffect {
            _ = rtmpStream.unregisterVideoEffect(currentEffect)
        }
        switch segment.selectedSegmentIndex {
        case 1:
            currentEffect = MonochromeEffect()
            _ = rtmpStream.registerVideoEffect(currentEffect!)
        case 2:
            currentEffect = PronamaEffect()
            _ = rtmpStream.registerVideoEffect(currentEffect!)
        default:
            break
        }
    }
    
    @objc
    private func didInterruptionNotification(_ notification: Notification) {
        logger.info(notification)
    }
    
    @objc
    private func didRouteChangeNotification(_ notification: Notification) {
        logger.info(notification)
    }
    
    @objc
    private func on(_ notification: Notification) {
        guard let orientation = DeviceUtil.videoOrientation(by: UIApplication.shared.statusBarOrientation) else {
            return
        }
        rtmpStream.orientation = orientation
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if Thread.isMainThread {
            currentFPSLabel?.text = "\(rtmpStream.currentFPS)"
        }
    }
}

extension LiveViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider else { return }
        
        itemProvider.loadFileRepresentation(forTypeIdentifier: "public.item") { url, error in
            if let url = url as NSURL?, let filePathURL = url.fileReferenceURL(), filePathURL.absoluteString.contains(".gif") {
                itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { [weak self] data, _ in
                    guard let self = self else { return }
                    guard let data = data else { return }
                    
                    if let frameList = self.changeDataToImageArray(data: data), self.bannerSettingsView != nil {
                        DispatchQueue.main.async { [unowned self] in
                            self.bannerSettingsView.imageArray = frameList
                        }
                    }
                }
            } else {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                            if let image = image as? UIImage, self.bannerSettingsView != nil {
                                DispatchQueue.main.async { [unowned self] in
                                    self.bannerSettingsView.imageArray = [image]
                            }
                        }
                    }
                } else {
                    // TODO: Handle empty results or item provider not being able load UIImage
                }
            }
        }
    }
    
    func changeDataToImageArray(data: Data) -> [UIImage]? {
        print(data)
        
        let gifOptions = [
            kCGImageSourceShouldAllowFloat as String: true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String: true as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, gifOptions) else {
            debugPrint("Cannot create image source with data!")
            return nil
        }
        
        let framesCount = CGImageSourceGetCount(imageSource)
        var frameList = [UIImage]()
        
        for index in 0 ..< framesCount {
            if let cgImageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) {
                let uiImageRef = UIImage(cgImage: cgImageRef)
                frameList.append(uiImageRef)
            }
        }
        
        return frameList
    }
}

extension LiveViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
