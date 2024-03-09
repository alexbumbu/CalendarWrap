//
//  PhotosCollectionViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 09.03.2024.
//

import UIKit
import AlamofireImage
import MBProgressHUD

private typealias DataSource = UICollectionViewDiffableDataSource<PhotoAlbum, GooglePhoto>

private struct PhotosCollectionViewControllerPage {
    
    var album: PhotoAlbum?
    var albumNextPageToken: String?
}

class PhotosCollectionViewController: UICollectionViewController {
    
    private enum Segue: String, SegueNavigation {
        case showPhotoPreviewSegue
        
        var identifier: String { rawValue }
    }
    
    private enum Constants {
        static let photoCellIdentifier = "photoCell"
        static let headerViewIdentifier = "headerView"
        static let footerViewIdentifier = "footerView"
        
        static let pageSize = 25
        
        static let cellSize = CGSize(width: 128, height: 128)
        static let footerViewSize = CGSize(width: 0, height: 126)
        
        static let thumbnailSize = cellSize.applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
    }
    
    var didSelectPhoto: ((GooglePhoto) -> Void)?
    
    private var albums = [PhotoAlbum]()
    
    private var nextPage = PhotosCollectionViewControllerPage()
    private var dataSource: DataSource!
    
    private var fetching = false
    private var photoToPreview: GooglePhoto?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        
        setupDataSource()
        
        Task {
            await fetchAlbums()
            await fetchNextPage()
        }
    }
    
    @IBSegueAction func showPhotoPreview(_ coder: NSCoder) -> PhotoPreviewViewController? {
        guard let photoToPreview else {
            return nil
        }
        
        return PhotoPreviewViewController(photo: photoToPreview, coder: coder)
    }
}

extension PhotosCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        fetchPage(for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        /* because of having dynamic sections (the number of items is not set when the data source is constructed) and
         relying on collectionView(_:, willDisplay:, forItemAt: IndexPath) for fetching next items, it can end up in a
         scenario where collectionView(_:, willDisplay:, forItemAt: IndexPath) is not triggered because all the items
         for the last visible section are loaded and the next sections are empty. As a workaround for this we're using
         section footers and trigger fetching the next items. */
        
        guard elementKind == UICollectionView.elementKindSectionFooter else {
            return
        }
        
        fetchPage(for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = albums[indexPath.section]
        
        if let photo = album.photos?[indexPath.item] {
            didSelectPhoto?(photo)
        }
    }
}

extension PhotosCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard section == albums.count-1 else {
            return CGSize(width: 0, height: 1)
        }
        
        return Constants.footerViewSize
    }
}

extension PhotosCollectionViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let downloader = ImageDownloader()
        
        for indexPath in indexPaths {
            guard let photos = albums[indexPath.section].photos, indexPath.item < photos.count else {
                continue
            }
            
            let photo = photos[indexPath.item]
            
            let urlRequest = URLRequest(url: photo.url(size: Constants.thumbnailSize, maintainingAspectRatio: true)!)
            downloader.download(urlRequest)
        }
    }
}

private extension PhotosCollectionViewController {
    
    func setupDataSource() {
        dataSource = DataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.photoCellIdentifier, for: indexPath) as? PhotoCell
            cell?.didLongPress = { [weak self] in
                guard let this = self else {
                    return
                }
                
                this.photoToPreview = item
                Segue.showPhotoPreviewSegue.perform(in: this, sender: nil)
            }
            
            cell?.imageView.af.setImage(withURL: item.url(size: Constants.thumbnailSize, maintainingAspectRatio: true)!, placeholderImage: UIImage(systemName: "photo"))
            
            return cell
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let this = self else {
                return nil
            }
            
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let album = this.albums[indexPath.section]
                
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.headerViewIdentifier, for: indexPath) as? PhotoAlbumHeaderView
                headerView?.titleNameLabel.text = "\(album.title) (\(album.photos?.count ?? 0)/\(album.photosCount))"
                
                return headerView
                
            case UICollectionView.elementKindSectionFooter:
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.footerViewIdentifier, for: indexPath)

                return footerView
                
            default:
                return nil
            }
        }
    }
    
    func updateDataSource() {
        var updatesSnapshot = NSDiffableDataSourceSnapshot<PhotoAlbum, GooglePhoto>()
        for album in albums {
            updatesSnapshot.appendSections([album])
            updatesSnapshot.appendItems([], toSection: album)
        }
        
        dataSource.apply(updatesSnapshot, animatingDifferences: true)
    }
    
    func fetchAlbums() async {
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
        guard let albums = await GooglePhotosService.getAlbums() else {
            progressHUD.hide(animated: true)
            // TODO: show error alert
            return
        }
        
        progressHUD.hide(animated: true)
        
        self.albums = albums
        
        await MainActor.run {
            updateDataSource()
        }
    }
    
    func fetchPhotos(forAlbum albumId: String, pageToken: String?) async -> Int {
        let response = await GooglePhotosService.getPhotos(albumId: albumId, pageToken: pageToken)
        guard let album = albums.first(where: { $0.id == albumId }) else {
            return 0
        }
        
        if album.photos == nil {
            album.photos = [GooglePhoto]()
        }
                
        nextPage.albumNextPageToken = response.nextPageToken
        
        guard let photos = response.photos else {
            return 0
        }
        
        album.photos?.append(contentsOf: photos)
                
        var snapshot = dataSource.snapshot()
        snapshot.appendItems(photos, toSection: album)
        
        await MainActor.run {
            dataSource.apply(snapshot, animatingDifferences: true)
        }
        
        return photos.count
    }
    
    func fetchNextPage() async {
        guard !fetching else {
            return
        }
        
        fetching = true
            
        // when nextPage.album is nil set it to the first album
        if nextPage.album == nil {
            nextPage.album = albums.first
        }
        
        var fetchedPhotosCount = 0
                
        // process the albums until the desired page size is reached
        while let album = nextPage.album, fetchedPhotosCount < Constants.pageSize {
            repeat {
                let count = await fetchPhotos(forAlbum: album.id, pageToken: nextPage.albumNextPageToken)
                fetchedPhotosCount += count
            } while fetchedPhotosCount < Constants.pageSize && nextPage.albumNextPageToken != nil
            
            // move to the next album if all photos from the current album have been fetched
            if nextPage.albumNextPageToken == nil {
                if let currentIndex = albums.firstIndex(where: { $0.id == album.id }), currentIndex + 1 < albums.count {
                    nextPage.album = albums[currentIndex + 1]
                } else {
                    break
                }
            }
        }
        
        fetching = false
    }
    
    func fetchPage(for indexPath: IndexPath) {
        var shouldFetch = false
        let albumToDisplay = albums[indexPath.section]
        
        if let photos = albumToDisplay.photos {
            if photos.count < albumToDisplay.photosCount {
                shouldFetch = true
            }
        } else {
            shouldFetch = true
        }
        
        guard shouldFetch else {
            return
        }
        
        Task {
            await fetchNextPage()
        }
    }
}
