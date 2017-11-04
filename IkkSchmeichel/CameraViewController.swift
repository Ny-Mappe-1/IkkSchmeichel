import UIKit
import SwiftyCam
import Stellar

class CameraViewController : SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    var captureButton: UIButton!
    var flipCameraButton: UIButton!
    var flashButton: UIButton!
    
    var hud = JGProgressHUD(style: JGProgressHUDStyle.dark)!
    var lastImage: UIImage?
    var lastResult: FaceClient.Result?
    var confettiView: SAConfettiView?
    var schmeichelView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraDelegate = self
        shouldUseDeviceOrientation = true
        allowAutoRotate = true
        audioEnabled = false
        flashEnabled = false
        
        addButtons()
    }
    
    // SwiftyCamViewControllerDelegate
    
    private func addButtons() {
        let captureSize = CGSize(width: 69, height: 69)
        let captureFrameCenterY = view.frame.height - captureSize.height / 2 - 20
        let captureFrame = CGRect(x: view.frame.midX - captureSize.width / 2, y: captureFrameCenterY - captureSize.height / 2, width: captureSize.width, height: captureSize.height)
        let captureGutterWidth = view.frame.midX - captureSize.width
        captureButton = UIButton(frame: captureFrame)
        captureButton.setImage(#imageLiteral(resourceName: "Capture"), for: UIControlState())
        captureButton.addTarget(self, action: #selector(capture(_:)), for: .touchUpInside)
        self.view.addSubview(captureButton)
        
        let flipSize = CGSize(width: 42, height: 35)
        let flipFrame = CGRect(x: (captureGutterWidth / 2 - flipSize.width / 2), y: captureFrameCenterY - flipSize.height / 2, width: flipSize.width, height: flipSize.height)
        flipCameraButton = UIButton(frame: flipFrame)
        flipCameraButton.setImage(#imageLiteral(resourceName: "Flip"), for: UIControlState())
        flipCameraButton.addTarget(self, action: #selector(flipCamera(_:)), for: .touchUpInside)
        self.view.addSubview(flipCameraButton)
        
        let flashSize = CGSize(width: 38, height: 42)
        let flashFrame = CGRect(x: (view.frame.midX + captureSize.width + captureGutterWidth / 2 - flashSize.width / 2), y: captureFrameCenterY - flashSize.height / 2, width: flashSize.width, height: flashSize.height)
        flashButton = UIButton(frame: flashFrame)
        flashButton.setImage(#imageLiteral(resourceName: "ZapOutline"), for: UIControlState())
        flashButton.addTarget(self, action: #selector(toggleFlash(_:)), for: .touchUpInside)
        self.view.addSubview(flashButton)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        self.lastImage = normalizeImageRotation(photo)
        let data = UIImageJPEGRepresentation(self.lastImage!, 0.8)
        checkPhoto(jpeg: data!)
    }
    
    func normalizeImageRotation(_ image: UIImage) -> UIImage {
        if (image.imageOrientation == UIImageOrientation.up) { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    @objc private func capture(_ sender: UIButton) {
        hud.indicatorView = JGProgressHUDPieIndicatorView(hudStyle: hud.style)
        hud.show(in: self.view)
        hud.progress = 0

        takePhoto()
//        swiftyCam(self, didTake: #imageLiteral(resourceName: "Hjortshoej.jpg"))
    }
    
    @objc private func flipCamera(_ sender: UIButton) {
        switchCamera()
    }
    
    @objc private func toggleFlash(_ sender: UIButton) {
        flashEnabled = !flashEnabled
        
        if flashEnabled {
            flashButton.setImage(#imageLiteral(resourceName: "ZapFilled"), for: UIControlState())
        } else {
            flashButton.setImage(#imageLiteral(resourceName: "ZapOutline"), for: UIControlState())
        }
    }
    
    private func checkPhoto(jpeg: Data?) {
        self.captureButton.isEnabled = false
        
        FaceClient.check(data: jpeg!, progressHandler: { progress in
            self.hud.progress = Float(progress.fractionCompleted)
        }) { result in
            self.lastResult = result
            self.captureButton.isEnabled = true
            
            if result.identical {
                self.hud.dismiss(animated: false)
                self.celebrate()
            } else {
                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()

                delay(secs: 2, then: {
                    self.hud.dismiss(animated: false)
                })
            }
        }
    }
    
    func celebrate() {
        let confettiView = SAConfettiView(frame: self.view.bounds)
        self.view.insertSubview(confettiView, at: 1)
        confettiView.startConfetti()
        self.confettiView = confettiView
        
        let imgView = UIImageView(image: #imageLiteral(resourceName: "TotallySchmeichel"))
        self.view.addSubview(imgView)
        imgView.center = self.view.center
        
        imgView
            .repeatCount(999)
            .makeSize(CGSize(width: 496, height: 318)).rotate(360).duration(50)
            .then().makeSize(CGSize(width: 100, height: 63)).rotate(360).duration(50)
            .animate()
        self.schmeichelView = imgView
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if let view = self.schmeichelView { view.removeFromSuperview() }
        if let view = self.confettiView { view.removeFromSuperview() }
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        guard let image = self.lastImage else { return }
        guard let result = self.lastResult else { return }

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Detail") as! DetailViewController
        self.present(vc, animated: true, completion: nil)
        
        vc.imageView.image = image
        vc.textView.text = String(describing: result.json!)
    }
}

func delay(secs: Double, then: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
        then()
    }
}
