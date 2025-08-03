//
//  PhotosPreviewViewController.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 12.01.2024.
//

import UIKit
import MBProgressHUD

class PhotoPreviewViewController: UIViewController {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    
    private let photo: GooglePhoto
    
    private var pointToCenterAfterResize: CGPoint = .zero
    private var scaleToRestoreAfterResize: CGFloat = 0.0
    
    init?(photo: GooglePhoto, coder: NSCoder) {
        self.photo = photo
        super.init(coder: coder)
    }

    @available(*, unavailable, renamed: "init(photo:coder:)")
    required init?(coder: NSCoder) {
        fatalError("Invalid way of decoding this class")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.decelerationRate = .fast
                        
        updateImageView(for: view.frame.size)
                                        
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        // using setImage(withURL:) completion handler doesn't center the image when it's cached. Instead, I'm relying on imageTransition completion handler.
        imageView.af.setImage(withURL: photo.url!, imageTransition: .custom(duration: 0, animationOptions: .beginFromCurrentState, animations: { imageView, image in
            imageView.image = image
        }, completion: { [weak self] _ in
            self?.centerImageView()
            progressHUD.hide(animated: true)
        }), runImageTransitionIfCached: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateSupportedInterfaceOrientations(.allButUpsideDown)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        updateSupportedInterfaceOrientations(.portrait)
    }

    @IBAction func closeAction() {
        dismiss(animated: true)
    }
}

extension PhotoPreviewViewController: UIScrollViewDelegate {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        prepareToResize()
        coordinator.animate { [weak self] context in
            self?.updateImageView(for: context.containerView.bounds.size)
            self?.centerImageView()
            self?.recoverFromResizing()
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}


private extension PhotoPreviewViewController {
    
    func updateSupportedInterfaceOrientations(_ supportedOrientations: UIInterfaceOrientationMask) {
        (UIApplication.shared.delegate as? AppDelegate)?.supportedInterfaceOrientations = supportedOrientations
        setNeedsUpdateOfSupportedInterfaceOrientations()
    }
    
    func updateImageView(for size: CGSize) {
        var aspectRatio = photo.size.height/photo.size.width
        var width = size.width
        var height = width * aspectRatio
        
        if height > size.height {
            aspectRatio = photo.size.width/photo.size.height
            height = size.height
            width = height * aspectRatio
        }
        
        // adjust the size by the zoom scaling factor
        let scale = scrollView.zoomScale
        var newFrame = imageView.frame
        newFrame.size = CGSize(width: width, height: height).applying(CGAffineTransform(scaleX: scale, y: scale))
        
        imageView.frame = newFrame
    }
    
    func centerImageView() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
}
    
// MARK: Rotation Support
private extension PhotoPreviewViewController {
    
    private var maximumContentOffset: CGPoint {
        let contentSize = scrollView.contentSize;
        let boundsSize = scrollView.bounds.size;
        
        return CGPoint(x: contentSize.width - boundsSize.width, y: contentSize.height - boundsSize.height)
    }

    private var minimumContentOffset: CGPoint {
        .zero;
    }
    
    func prepareToResize() {
        let boundsCenter = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
        pointToCenterAfterResize = scrollView.convert(boundsCenter, to: imageView)
        
        scaleToRestoreAfterResize = scrollView.zoomScale
        
        if (scaleToRestoreAfterResize <= scrollView.minimumZoomScale + CGFloat(Float.ulpOfOne)) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    func recoverFromResizing() {
        // restore zoom scale, first making sure it is within the allowable range
        let maxZoomScale = max(scrollView.minimumZoomScale, scaleToRestoreAfterResize)
        scrollView.zoomScale = min(scrollView.maximumZoomScale, maxZoomScale)
        
        // restore center point, by calculating the content offset that would yield the center point, first making sure it is within the allowable range
        let boundsCenter = scrollView.convert(pointToCenterAfterResize, from: imageView)
        
        var offset = CGPoint(x: boundsCenter.x - scrollView.bounds.width/2.0,
                             y: boundsCenter.y - scrollView.bounds.height/2.0)
        
        let minOffset = minimumContentOffset
        let maxOffset = maximumContentOffset
        
        var realMaxOffset: CGFloat = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        scrollView.contentOffset = offset
    }
}
