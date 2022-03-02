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
    
    @IBOutlet weak var effectView: UIView!
    @IBOutlet weak var effectControlView: UIView!
    
    private var rtmpConnection = RTMPConnection()
    private var rtmpStream: RTMPStream!
    private var sharedObject: RTMPSharedObject!
    private var currentEffect: VideoEffect?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var retryCount: Int = 0
    private var subscriptions = Set<AnyCancellable>()
    
    var filterMenuView: ImageFilterMenuView!
    
    var viewModel = ViewModel()
    
    var cancelBag = Set<AnyCancellable>()
    
    var publishSizeRatio: CGSize {
        return CGSize(width: (lfView.bounds.size.width/self.viewModel.currentResolution.width), height: (lfView.bounds.size.height/self.viewModel.currentResolution.height))
    }
    
    var screenSizeRatio: CGSize {
        return CGSize(width: (self.viewModel.currentResolution.width/lfView.bounds.size.width), height: (self.viewModel.currentResolution.height/lfView.bounds.size.height))
    }
    
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
            .width: self.viewModel.currentResolution.width,
            .height: self.viewModel.currentResolution.height,
            .profileLevel: kVTProfileLevel_H264_High_AutoLevel
        ]
        //rtmpStream.mixer.recorder.delegate = ExampleRecorderDelegate.shared
        
        videoBitrateSlider?.value = Float(RTMPStream.defaultVideoBitrate) / 1000
        audioBitrateSlider?.value = Float(RTMPStream.defaultAudioBitrate) / 1000
        
        lfView.videoGravity = .resize
        lfView.isUserInteractionEnabled = true
        
        //        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapScreen(_:)))
        //        lfView.gestureRecognizers = [tapRecognizer]
        
        NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.viewModel.configPhotosUI()
    }
    
    
    @IBAction func tapAddBannerBtn(_ sender: Any) {
        filterMenuView = ImageFilterMenuView(frame: self.view.frame)
        filterMenuView.addBtn.addTarget(self, action: #selector(selectPhotos), for: .touchUpInside)
        self.view.addSubview(filterMenuView)
    }
    
    //    @objc func tapCloseBtn(_ sender: Any) {
    //        self.bannerSettingsView.removeFromSuperview()
    //        self.bannerSettingsView = nil
    //    }
    
    //    fileprivate func hideImageControlView(id: Int, delay: Double) {
    //        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
    //            if let searchIndex = self.imageFilterArray.firstIndex(where: { $0.id == id }) {
    //                let changedView = self.imageControlViewArray[searchIndex]
    //                changedView.isHidden = true
    //                self.imageControlViewArray[searchIndex] = changedView
    //            }
    //        }
    //    }
    
    //    @objc func tapScreen(_ gesture: UIGestureRecognizer) {
    //        guard let gestureView = gesture.view else {
    //            return
    //        }
    //
    //        let touchPoint: CGPoint = gesture.location(in: gestureView)
    //        print("touchPoint", touchPoint)
    //
    //        for (index, controlView) in self.imageControlViewArray.enumerated().reversed() {
    //            let filterRect = controlView.frame
    //
    //            if (touchPoint.x>=filterRect.minX && filterRect.maxX >= touchPoint.x) &&
    //                (touchPoint.y>=filterRect.minY && filterRect.maxY >= touchPoint.y) {
    //
    //                let imgFilter = self.imageFilterArray[index]
    //
    //                DispatchQueue.main.async {
    //                    UIView.animate(withDuration: 0.5) {
    //                        let changedView = controlView
    //                        changedView.isHidden = false
    //                        self.imageControlViewArray[index] = changedView
    //                        self.hideImageControlView(id: imgFilter.id, delay: 3.0)
    //                    }
    //                }
    //                return
    //            }
    //        }
    //
    //    }
    
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
    }
    
    @objc func selectPhotos() {
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
            //        case 1:
            //            currentEffect = MonochromeEffect()
            //            _ = rtmpStream.registerVideoEffect(currentEffect!)
            //        case 2:
            //            currentEffect = PronamaEffect()
            //            _ = rtmpStream.registerVideoEffect(currentEffect!)
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

extension LiveViewController {
    fileprivate func updateImageFilter(_ imageFilter: [ImageFilter]) {
        if let currentEffect: VideoEffect = self.currentEffect {
            _ = self.rtmpStream.unregisterVideoEffect(currentEffect)
        }
        
        self.currentEffect = ImageFilterEffect(layer: imageFilter)
        _ = self.rtmpStream.registerVideoEffect(self.currentEffect!)
    }
    
    fileprivate func updatePosition() -> (Int, CGRect) -> Void {
        return { [unowned self] (viewId, changeFrame) in
            
            let changeIndex = self.viewModel.filterList.firstIndex {
                $0.filter.id == viewId
            }!
            
            let publishPoint = CGPoint(
                x: changeFrame.origin.x * self.viewModel.screenRatio.width,
                y: changeFrame.origin.y * self.viewModel.screenRatio.height)
            
            let publishSize = CGSize(
                width: changeFrame.size.width * self.viewModel.screenRatio.width,
                height: changeFrame.size.height * self.viewModel.screenRatio.height)
            
            let publishRect = CGRect(origin: publishPoint, size: publishSize)
            
            var imgFilter = self.viewModel.filterList[changeIndex].filter
            imgFilter.rect = publishRect
            
            self.viewModel.filterList[changeIndex].filter = imgFilter
            
            // publish image
            self.updateImageFilter(self.viewModel.filterList
                                    .map{ $0.filter })
            
            // update control view position
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self = self else { return }
                self.viewModel.filterList[changeIndex].menu.sizeControl.center = CGPoint(x: changeFrame.maxX - 5,
                                                                                         y: changeFrame.maxY - 5)
                self.viewModel.filterList[changeIndex].menu.closeButton.center = CGPoint(x: changeFrame.maxX - 5,
                                                                                         y: changeFrame.origin.y + 5)
            }
        }
    }
    
    fileprivate func publishImageFilter(_ imageArray: [UIImage]) {
        let image: UIImage = imageArray[0]
        
        let imageInfo = ImageInfo(size: image.size,
                                  ratio: max(image.size.width, image.size.height))
        
        var publishSize = CGSize(width: image.size.width,
                                 height: image.size.height)
        
        var screenScaledSize = CGSize(
            width: publishSize.width * publishSizeRatio.width,
            height: publishSize.height * publishSizeRatio.height)
        
        if publishSize.width > self.viewModel.currentResolution.width * 0.9 {
            let maxLength = self.viewModel.currentResolution.width * 0.9
            let scaleFactor = maxLength / imageInfo.ratio
            
            publishSize = CGSize(width: publishSize.width * scaleFactor,
                                 height: publishSize.height * scaleFactor)
            screenScaledSize = CGSize(
                width: publishSize.width * publishSizeRatio.width,
                height: publishSize.height * publishSizeRatio.height)
        }
        
        //first position
        //screen center position
        let publishRect = CGRect(origin: CGPoint(x: (self.viewModel.currentResolution.width/2) - (publishSize.width/2) , y: (self.viewModel.currentResolution.height/2) - (publishSize.height/2)), size: publishSize)
        
        print("publishRect", publishRect)
        
        let imgFilter: ImageFilter = ImageFilter(rect: publishRect, imageArray: imageArray, info: imageInfo)
        
        let controlView = ImageFilterControlView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: screenScaledSize))
        controlView.center = self.view.center
        
        controlView.tag = imgFilter.id
        
        let sizeControlView = ImageSizeControlView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30)))
        sizeControlView.center = CGPoint(x: controlView.frame.maxX - 5, y: controlView.frame.maxY - 5)
        sizeControlView.tag = imgFilter.id
        
        let closeBtn = ImageControlCloseButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 30, height: 30)))
        closeBtn.center = CGPoint(x: controlView.frame.maxX - 5, y: controlView.frame.origin.y + 5)
        closeBtn.tag = imgFilter.id
        
        let filterMenu = ImageFilterMenu(controlView: controlView, sizeControl: sizeControlView, closeButton: closeBtn)
        let filterData = ImageFilterData(menu: filterMenu, filter: imgFilter)
        
        sizeControlView.dragEvent
            .sink(receiveValue: { [unowned self] (viewId, beginPoint, endPoint, translation) in
                print("dragEvent", viewId, beginPoint, endPoint, translation)
                
                let changeIndex = self.viewModel.filterList.firstIndex {
                    $0.filter.id == viewId
                }!
                
                let resizeCondition = self.viewModel.isResizeTargetView(beginPoint: beginPoint,
                                                         endPoint: endPoint)
                
                guard resizeCondition != .none else { return }
                
                let resizeValue = self.CGPointDistance(from: beginPoint, to: endPoint)
                                
                let bottomTrailingPoint = CGPoint(x: filterData.menu.sizeControl.center.x + translation.x,
                                                  y: filterData.menu.sizeControl.center.y + translation.y)
                
                var filterData = self.viewModel.filterList[changeIndex]

                let resultRect = self.viewModel.getTargetViewRect(resizeCondition,
                                                   filterData: filterData,
                                                   resizeValue: resizeValue,
                                                   bottomTrailingPoint: bottomTrailingPoint)
                
                let lastCenterPos = filterData.menu.controlView.center
                
                filterData.menu.controlView.frame = resultRect
                filterData.menu.controlView.center = lastCenterPos
                
                let publishSize = CGSize(width: resultRect.size.width/publishSizeRatio.width,
                                         height: resultRect.size.height/publishSizeRatio.height)
                                
                let publishPoint = CGPoint(
                    x: filterData.menu.controlView.frame.origin.x * self.viewModel.screenRatio.width,
                    y: filterData.menu.controlView.frame.origin.y * self.viewModel.screenRatio.height)
               
                let publishRect = CGRect(origin: publishPoint, size: publishSize)
                
                filterData.filter.rect = publishRect
                self.viewModel.filterList[changeIndex] = filterData

                self.updateImageFilter(self.viewModel.filterList.map({
                    return $0.filter
                }))
                
                UIView.animate(withDuration: 0.1) {
                    filterData.menu.sizeControl.center = CGPoint(x: filterData.menu.controlView.frame.maxX - 5,
                                                                 y: filterData.menu.controlView.frame.maxY - 5)
                    filterData.menu.closeButton.center = CGPoint(x: filterData.menu.controlView.frame.maxX - 5,
                                                                 y: filterData.menu.controlView.frame.origin.y + 5)
                }
            })
            .store(in: &self.cancelBag)
        
        controlView.panEvent
            .sink(receiveValue: updatePosition())
            .store(in: &self.cancelBag)
        
        controlView.pinchEvent
            .sink(receiveValue: updatePosition())
            .store(in: &self.cancelBag)
        
        controlView.tapEvent
            .sink(receiveValue: { [unowned self] (viewId) in
                print("tapEvent", viewId)
            })
            .store(in: &self.cancelBag)
        
        closeBtn.closeEvent
            .sink(receiveValue: { [unowned self] (viewId) in
                print("closeEvent", viewId)
                
                //                DispatchQueue.main.async() {
                //                    if let searchIndex = self.imageFilterArray.firstIndex(where: { $0.id == id }) {
                //                        self.imageFilterArray.remove(at: searchIndex)
                //                        UIView.animate(withDuration: 0.5) {
                //                            self.imageControlViewArray[searchIndex].removeFromSuperview()
                //                        }
                //                        self.imageControlViewArray.remove(at: searchIndex)
                //
                //                        self.updateImageFilter(self.imageFilterArray)
                //                    }
                //                }
            })
            .store(in: &self.cancelBag)
        
        self.viewModel.filterList.append(filterData)
        
        self.filterMenuView.addSubview(controlView)
        self.filterMenuView.addSubview(sizeControlView)
        self.filterMenuView.addSubview(closeBtn)
        
        self.updateImageFilter(self.viewModel.filterList.map({
            return $0.filter
        }))
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
                    
                    guard let imageArray = self.viewModel.changeDataToImageArray(data: data) else { return }
                    DispatchQueue.main.async { [unowned self] in
                        self.publishImageFilter(imageArray)
                    }
                }
            } else {
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        guard let image = image as? UIImage else { return }
                        DispatchQueue.main.async { [unowned self] in
                            publishImageFilter([image])
                        }
                    }
                } else {
                    // TODO: Handle empty results or item provider not being able load UIImage
                }
            }
        }
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
