//
//  PhotosPickerViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 10.01.2024.
//

import UIKit

class PhotosPickerViewController: UIViewController {
    
    private enum Segue: String, SegueNavigation {
        case embedPhotosCollectionSegue
        
        var identifier: String { rawValue }
    }
    
    var didSelectPhoto: ((GooglePhoto) -> Void)?
    
    @IBOutlet private weak var usePhotoButton: UIButton!
    
    private var selectedPhoto: GooglePhoto? {
        didSet {
            usePhotoButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.embedPhotosCollectionSegue.identifier {
            if let viewController = segue.destination as? PhotosCollectionViewController {
                viewController.didSelectPhoto = { [weak self] photo in
                    self?.selectedPhoto = photo
                }
            }
        }
    }
    
    @IBAction func usePhotoAction() {
        guard let selectedPhoto else {
            return
        }
        
        didSelectPhoto?(selectedPhoto)
        dismiss(animated: true)
    }
}
