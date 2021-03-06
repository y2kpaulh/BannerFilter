#if os(tvOS)

import CoreMedia
import Foundation

typealias AVCaptureOutput = Any
typealias AVCaptureConnection = Any

protocol AVCaptureVideoDataOutputSampleBufferDelegate: AnyObject {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

protocol AVCaptureAudioDataOutputSampleBufferDelegate: AnyObject {
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}

#endif
