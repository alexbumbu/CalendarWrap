//
//  PhotosPreviewViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 12.01.2024.
//

import UIKit
import MBProgressHUD

class PhotoPreviewViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    
    private let photo: GooglePhoto
    
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
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        imageView.af.setImage(withURL: photo.url!, completion: {_ in
            progressHUD.hide(animated: true)
        })
    }

    @IBAction func closeAction() {
        dismiss(animated: true)
    }
}
