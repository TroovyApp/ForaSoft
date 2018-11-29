//
//  TroovyExtensions.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Photos

extension UIRefreshControl {
    
    func setRefreshing(_ refreshing: Bool) {
        if refreshing {
            if !self.isRefreshing {
                self.beginRefreshing()
            }
        } else {
            if self.isRefreshing {
                self.endRefreshing()
            }
        }
    }
    
}


extension UICollectionView {
    
    func setEmptyView() {
        let emptyImage = UIImageView(image: UIImage(named: "empty_tab_1"))
        self.backgroundView = emptyImage
    }
    
    func removeEmptyView() {
        self.backgroundView = nil
    }
}

extension UIButton {
    
    private struct AssociatedKey {
        static var animationCircleLayer = "animationCircleLayer"
        static var fadeInAnimation = "fadeInAnimation"
    }
    
    func enableButton() {
        self.backgroundColor = UIColor.tv_purpleColor()
        self.setTitleColor(UIColor.white, for: .normal)
        self.isUserInteractionEnabled = true
    }
    
    func disableButton() {
        self.backgroundColor = UIColor.tv_grayLightColor()
        self.setTitleColor(UIColor.tv_darkColor().withAlphaComponent(0.4), for: .normal)
        self.isUserInteractionEnabled = false
    }
    
    func enableClearButton() {
        self.setTitleColor(UIColor.tv_purpleColor(), for: .normal)
        self.isUserInteractionEnabled = true
    }
    
    func disableClearButton() {
        self.setTitleColor(UIColor.tv_darkColor().withAlphaComponent(0.2), for: .normal)
        self.isUserInteractionEnabled = false
    }
    
    var animationLayer: CALayer {
        var layer = objc_getAssociatedObject(self, &AssociatedKey.animationCircleLayer)
        if layer != nil {
            return layer as! CALayer
        }
        layer = createAnimationLayer()
        objc_setAssociatedObject(self, &AssociatedKey.animationCircleLayer, layer!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return layer as! CALayer
    }
    
    private func createAnimationLayer() -> CALayer {
        let animLayer = CALayer()
        animLayer.frame = self.bounds
            //CGRect(x: -10, y: -10, width: self.bounds.size.width + 20, height: self.bounds.size.height + 20)
        animLayer.cornerRadius = animLayer.frame.width/2
        animLayer.backgroundColor = UIColor.tv_purpleColor().cgColor
        animLayer.opacity = 0.0
        
        return animLayer
    }
    
    //REQUIRES clips to bounds set to false!
    func playBounceAnimation() {
        self.layer.insertSublayer(animationLayer, below: self.imageView?.layer)
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "opacity");
        animation.fromValue = animationLayer.opacity
        animation.duration = 0.3
        animationLayer.opacity = 0.4
        animationLayer.add(animation, forKey: AssociatedKey.fadeInAnimation)
        UIView.animate(withDuration: 0.3,
                       animations: {
        
                        self.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                        self.animationLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 1.4, y: 1.4))
                        
        },
        completion: { Void in
            UIView.animate(withDuration: 2.0,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(0.4),
                           initialSpringVelocity: CGFloat(4.0),
                           options: UIViewAnimationOptions.allowUserInteraction,
                           animations: {
                            self.transform = CGAffineTransform.identity
            })
        }
        )
    }
    
    func stopBounceAnimation() {
        self.animationLayer.opacity = 0.0
        self.animationLayer.removeFromSuperlayer()
    }
}

extension UIColor {
    
    class func tv_redColor() -> UIColor {
        return UIColor(red: 255.0 / 255.0, green: 46.0 / 255.0, blue: 49.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_redTextColor() -> UIColor {
        return UIColor(red: 237.0 / 255.0, green: 106.0 / 255.0, blue: 122.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_grayTextColor() -> UIColor {
        return UIColor(red: 166.0 / 255.0, green: 176.0 / 255.0, blue: 189.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_lightGrayTextColor() -> UIColor {
        return UIColor(red: 106.0 / 255.0, green: 106.0 / 255.0, blue: 119.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_grayColor() -> UIColor {
        return UIColor(red: 219.0 / 255.0, green: 222.0 / 255.0, blue: 226.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_grayLightColor() -> UIColor {
        return UIColor(red: 247.0 / 255.0, green: 250.0 / 255.0, blue: 253.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_graySemiDarkColor() -> UIColor {
        return UIColor(red: 200.0 / 255.0, green: 194.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_grayDarkColor() -> UIColor {
        return UIColor(red: 138.0 / 255.0, green: 138.0 / 255.0, blue: 143.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_blueTextColor() -> UIColor {
        return UIColor(red: 71.0 / 255.0, green: 60.0 / 255.0, blue: 188.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_purpleTextColor() -> UIColor {
        return UIColor(red: 155.0 / 255.0, green: 122.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_purpleColor() -> UIColor {
        return UIColor(red: 105.0 / 255.0, green: 0.0, blue: 255.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_darkColor() -> UIColor {
        return UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 61.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_darkTextColor() -> UIColor {
        return UIColor(red: 104.0 / 255.0, green: 114.0 / 255.0, blue: 128.0 / 255.0, alpha: 1.0)
    }
    
    class func tv_backgroundViewColor() -> UIColor {
        return UIColor.white
    }
    
    class func transitionColor(fromColor: UIColor, toColor: UIColor, progress: CGFloat) -> UIColor {
        var percentage = progress < 0 ?  0 : progress
        percentage = percentage > 1 ?  1 : percentage
        
        var fRed:CGFloat = 0
        var fBlue:CGFloat = 0
        var fGreen:CGFloat = 0
        var fAlpha:CGFloat = 0
        
        var tRed:CGFloat = 0
        var tBlue:CGFloat = 0
        var tGreen:CGFloat = 0
        var tAlpha:CGFloat = 0
        
        fromColor.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        toColor.getRed(&tRed, green: &tGreen, blue: &tBlue, alpha: &tAlpha)
        
        let red:CGFloat = (percentage * (tRed - fRed)) + fRed;
        let green:CGFloat = (percentage * (tGreen - fGreen)) + fGreen;
        let blue:CGFloat = (percentage * (tBlue - fBlue)) + fBlue;
        let alpha:CGFloat = (percentage * (tAlpha - fAlpha)) + fAlpha;
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}

extension URL {
    
    static func address(byAppendingServerAddress serverAddress: String, toContentPath path: String?) -> URL? {
        guard let contentPath = path, !contentPath.isEmpty, !serverAddress.isEmpty else {
            return nil
        }
        
        let address = serverAddress + contentPath
        if contentPath.hasPrefix("/") {
            let clearAddress = serverAddress + contentPath[contentPath.index(after: contentPath.startIndex)..<contentPath.endIndex]
            return URL(string: clearAddress)
        } else {
            return URL(string: address)
        }
    }
    
    func fixVideoOrientationAtURL(withCompletion completion: @escaping ((_ videoURL: URL) -> ())) {
        let fileExtension = self.pathExtension.lowercased()
        let asset = AVAsset(url: self)
        let fileName = "tmpVideo" + "." + fileExtension
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName, isDirectory: false)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        var frameSize = CGSize.zero
        var frameDuration = kCMTimeZero
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        
        var instructions: [AVMutableVideoCompositionInstruction] = []
        let composition = AVMutableComposition()
        for track in videoTracks {
            if UIImageOrientation.isVideoOrientationPortrait(fromTrack: track) {
                frameSize = CGSize(width: track.naturalSize.height, height: track.naturalSize.width)
            } else {
                frameSize = track.naturalSize
            }
            
            frameDuration = track.minFrameDuration
            
            let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? videoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: track, at: kCMTimeZero)
            
            if let compositionVideoTrack = videoTrack {
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                layerInstruction.setTransform(track.preferredTransform, at: kCMTimeZero)
                
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange =  CMTimeRangeMake(kCMTimeZero, asset.duration)
                instruction.layerInstructions = [layerInstruction]
                instructions.append(instruction)
            }
        }
        for track in audioTracks {
            let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: track, at: kCMTimeZero)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = frameDuration
        videoComposition.renderSize = frameSize
        videoComposition.instructions = instructions
        
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.outputFileType = (fileExtension == "mov" ? AVFileType.mov : AVFileType.mp4)
            exportSession.outputURL = fileURL
            exportSession.videoComposition = videoComposition
            exportSession.exportAsynchronously {
                var resultFileURL = self
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    resultFileURL = fileURL
                }
                
                completion(resultFileURL)
            }
        } else {
            completion(self)
        }
    }
    
}

extension UIImageOrientation {
    
    static func isVideoOrientationPortrait(fromTrack track: AVAssetTrack) -> Bool {
        let size = track.naturalSize
        let transform = track.preferredTransform
        
        if size.width == transform.tx && size.height == transform.ty {
            return false
        } else if transform.tx == 0 && transform.ty == 0 {
            return false
        } else if transform.tx == 0 && transform.ty == size.width {
            return true
        } else {
            return true
        }
    }
    
}

extension UIView {
    
    class func accessoryView(withSelector selector: Selector, target: Any) -> UIView {
        let flexButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: ApplicationMessages.ButtonsTitles.done, style: .plain, target: target, action: selector)
        let whiteImage = UIImage.image(fromColor: .white)
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = false
        toolbar.setBackgroundImage(whiteImage, forToolbarPosition: .any, barMetrics: .default)
        toolbar.sizeToFit()
        toolbar.setItems([flexButton, doneButton], animated: false)
        return toolbar
    }
    
}

extension Double {
    
    func tailingZeros() -> String {
        return String(format: "%g", self)
    }
    
}

extension UIViewController {
    
    // MARK: Alerts and Loaders Methods
    
    internal func showAlert(withErrorsMessages messages: [String]) {
        var message = ""
        for error in messages {
            message.append("\n• \(error)")
        }
        
        self.showAlert(withTitle: ApplicationMessages.AlertTitles.messages, message: message)
    }
    
    internal func showAlert(withTitle title: String, message: String?) {
        guard let text = message else {
            return
        }
        
        let alertController = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: ApplicationMessages.AlertButtonsTitles.close, style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    internal func openSettings() {
        guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, completionHandler: nil)
        }
    }
    
    internal func checkPhotosPermission(_ completion: @escaping ((_ granted: Bool) -> ())) {
        let photosPermission = PHPhotoLibrary.authorizationStatus()
        switch photosPermission {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                let granted = (status == .authorized)
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
            break
        case .authorized:
            completion(true)
            break
        default:
            completion(false)
            break
        }
    }
    
    internal func checkMicrophonePermission(_ completion: @escaping ((_ granted: Bool) -> ())) {
        let recordPermission = AVAudioSession.sharedInstance().recordPermission()
        switch recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
            break
        case .granted:
            completion(true)
            break
        default:
            completion(false)
            break
        }
    }
    
    internal func checkCameraPermission(_ completion: @escaping ((_ granted: Bool) -> ())) {
        let recordPermission = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch recordPermission {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
            break
        case .authorized:
            completion(true)
            break
        default:
            completion(false)
            break
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func hideButtonAction(_ sender: UIButton) {
        self.willMove(toParentViewController: nil)
        self.beginAppearanceTransition(false, animated: true)
        self.view.removeFromSuperview()
        self.endAppearanceTransition()
        self.removeFromParentViewController()
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        if let presentingViewController = self.presentingViewController {
            presentingViewController.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension UIImage {
    
    // MARK: Get Assets Images
    
    class func courseCellPlaceholder() -> UIImage {
        return #imageLiteral(resourceName: "tv_course_cell_image_placeholder")
    }
    
    class func tv_navbarBack() -> UIImage? {
        return #imageLiteral(resourceName: "tv_navbar_back")
    }
    
    class func tv_navbarCloseSmall() -> UIImage? {
        return #imageLiteral(resourceName: "tv_navbar_close_small")
    }
    
    class func tv_cameraPlaceholder() -> UIImage? {
        return #imageLiteral(resourceName: "tv_camera_placeholder_image")
    }
    
    class func tv_cameraSmallPlaceholder() -> UIImage? {
        return #imageLiteral(resourceName: "tv_camera_placeholder_image_small")
    }
    
    class func tv_plusWithBorderPlacehilder() -> UIImage? {
        return #imageLiteral(resourceName: "tv_add_button_image")
    }
    
    class func tv_profilePlaceholder() -> UIImage? {
        return #imageLiteral(resourceName: "tv_profile_placeholder_image")
    }
    
    class func tv_courseBacgroundPlaceholder() -> UIImage? {
        return #imageLiteral(resourceName: "tv_course_placeholder_bg")
    }
    
    class func tv_tutorialImage(withIndex index: Int) -> UIImage? {
        let imageName = "tv_tutorial_image_\(index)"
        return UIImage(named: imageName)
    }
    
    // MARK: Create Images
    
    class func image(fromColor color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }

        return nil
    }
    
    class func image(fromImage sourceImage: UIImage, scaledToWidth width: CGFloat, height: CGFloat) -> UIImage {
        if sourceImage.size.width <= width && sourceImage.size.height <= height {
            return sourceImage
        } else {
            let widthRatio = width / sourceImage.size.width
            let heightRatio = height / sourceImage.size.height
            
            var newSize = CGSize.zero
            if widthRatio < heightRatio {
                let newWidth = ceil(sourceImage.size.width * widthRatio)
                let newHeight = ceil(sourceImage.size.height * widthRatio)
                newSize = CGSize(width: newWidth, height: newHeight)
            } else {
                let newWidth = ceil(sourceImage.size.width * heightRatio)
                let newHeight = ceil(sourceImage.size.height * heightRatio)
                newSize = CGSize(width: newWidth, height: newHeight)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            sourceImage.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = scaledImage {
                return image
            } else {
                return sourceImage
            }
        }
    }
    
    class func roundedImage(fromImage sourceImage: UIImage, scaledToWidth width: CGFloat, height: CGFloat) -> UIImage {
        if sourceImage.size.width <= width && sourceImage.size.height <= height {
            return sourceImage
        } else {
            let widthRatio = width / sourceImage.size.width
            let heightRatio = height / sourceImage.size.height
            
            var newSize = CGSize.zero
            if widthRatio < heightRatio {
                let newWidth = ceil(sourceImage.size.width * widthRatio)
                let newHeight = ceil(sourceImage.size.height * widthRatio)
                newSize = CGSize(width: newWidth, height: newHeight)
            } else {
                let newWidth = ceil(sourceImage.size.width * heightRatio)
                let newHeight = ceil(sourceImage.size.height * heightRatio)
                newSize = CGSize(width: newWidth, height: newHeight)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            let context = UIGraphicsGetCurrentContext()
            context?.addEllipse(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
            context?.clip()
            sourceImage.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = scaledImage {
                return image
            } else {
                return sourceImage
            }
        }
    }
    
}

extension UIFont {
    class func tv_FontOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
    
    class func tv_SemiBoldFontOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }
}

extension String {
    func isValidDouble(maxDecimalPlaces: Int) -> Bool {

        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        let decimalSeparator = formatter.decimalSeparator ?? "."  // Gets the locale specific decimal separator. If for some reason there is none we assume "." is used as separator.
        
        if formatter.number(from: self) != nil {
            // Split our string at the decimal separator
            let split = self.components(separatedBy: decimalSeparator)
            
            let digits = split.count == 2 ? split.last ?? "" : ""
            return digits.count <= maxDecimalPlaces
        }
        
        return false // couldn't turn string into a valid number
    }
}

extension UILabel {
    
    func setLineHeight(lineHeight: CGFloat) {
        let text = self.text
        if let text = text {
            let attributeString = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            
            style.lineSpacing = lineHeight
            attributeString.addAttribute(NSAttributedStringKey.paragraphStyle, value: style, range: NSMakeRange(0, text.count))
            self.attributedText = attributeString
        }
    }
}

