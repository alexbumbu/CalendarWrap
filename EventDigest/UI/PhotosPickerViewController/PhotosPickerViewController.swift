//
//  PhotosPickerViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 10.01.2024.
//

import UIKit
import MBProgressHUD
import OSLog

private enum AlbumError: Error {
    case albumAlreadyVisible
    case albumNotFound
}

class PhotosPickerViewController: UIViewController {
    
    var didSelectPhoto: ((GooglePhoto) -> Void)?
    
    @IBOutlet private weak var usePhotoButton: UIButton!
    
    private weak var photosCollectionViewController: PhotosCollectionViewController?
    
    private var albums = [PhotoAlbum]()
    private var hiddenAlbums = [PhotoAlbum]()
    private var selectedPhoto: GooglePhoto? {
        didSet {
            usePhotoButton.isEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
            
            await fetchAlbums()
            photosCollectionViewController?.reload(albums: albums)
            
            progressHUD.hide(animated: true)
        }
    }
    
    @IBSegueAction func embedPhotosCollection(_ coder: NSCoder) -> PhotosCollectionViewController? {
        let viewController =  PhotosCollectionViewController(albums: albums, coder: coder)
        viewController?.didSelectPhoto = { [weak self] photo in
            self?.selectedPhoto = photo
        }
        
        photosCollectionViewController = viewController
        
        return viewController
    }
    
    @IBAction func usePhotoAction() {
        guard let selectedPhoto else {
            return
        }
        
        didSelectPhoto?(selectedPhoto)
        dismiss(animated: true)
    }
    
    @IBAction func showAlbumsVisibilityToggleAction(_ sender: UIBarButtonItem) {
        let vc: ToggleAlbumsVisibilityViewController = Storyboard.Photo.instantiateViewController(creator: { [weak self] coder in
            ToggleAlbumsVisibilityViewController(albums: self?.albums ?? [PhotoAlbum](),
                                     hiddenAlbums: self?.hiddenAlbums ?? [PhotoAlbum](),
                                     coder: coder)
        })
        
        let this = self
        vc.didHideAlbum = { album in
            this.hiddenAlbums.append(album)
            this.photosCollectionViewController?.hide(album: album)
        }
        vc.didShowAlbum = { album in
            do {
                let beforeAlbum = try this.getBeforeAlbum(album: album)
                this.photosCollectionViewController?.show(album: album, before: beforeAlbum)
            } catch {
                Logger.ui.error("error retrieving beforeAlbum: \(error)")
                return
            }
            
            this.hiddenAlbums.removeAll(where: { $0 == album })
        }
        
        vc.preferredContentSize = CGSize(width: view.bounds.width * 0.66, height: view.bounds.height * 0.4)
        vc.modalPresentationStyle = .popover
        vc.presentationController?.delegate = self
        vc.popoverPresentationController?.sourceItem = sender
        
        self.present(vc, animated: true)
        if let pop = vc.popoverPresentationController {
            
        }
    }
}

extension PhotosPickerViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

private extension PhotosPickerViewController {
    
    func fetchAlbums() async {
        guard let albums = await GooglePhotosService.getAlbums() else {
            // TODO: show error alert
            return
        }
                
        self.albums = albums
    }
    
    func getBeforeAlbum(album: PhotoAlbum) throws -> PhotoAlbum? {
        var visibleAlbums = [PhotoAlbum]()
        for album in albums {
            if !hiddenAlbums.contains(album) {
                visibleAlbums.append(album)
            }
        }
        
        if let index = visibleAlbums.firstIndex(of: album) {
            throw AlbumError.albumAlreadyVisible
        }
        
        guard let index = albums.firstIndex(of: album) else {
            throw AlbumError.albumNotFound
        }
        
        for visibleAlbum in visibleAlbums {
            if let a = albums.firstIndex(of: visibleAlbum), a > index {
                return visibleAlbum
            }
        }
        
        return nil
    }
}
