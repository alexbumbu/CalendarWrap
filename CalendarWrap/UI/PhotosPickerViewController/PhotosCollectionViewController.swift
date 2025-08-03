//
//  PhotosCollectionViewController.swift
//  CalendarWrap
//
//  Created by Alex Bumbu on 09.03.2024.
//

import UIKit
import AlamofireImage
import MBProgressHUD

private typealias DataSource = UICollectionViewDiffableDataSource<PhotoAlbum, Photo>

class PhotosCollectionViewController: UICollectionViewController {
    
    private enum Segue: String, SegueNavigation {
        case showPhotoPreviewSegue
        
        var identifier: String { rawValue }
    }
    
    private enum Constants {
        static let photoCellIdentifier = "photoCell"
        static let headerViewIdentifier = "headerView"
        static let footerViewIdentifier = "footerView"
                
        static let cellSize = CGSize(width: 128, height: 128)
    }
    
    var didSelectPhoto: ((GooglePhoto) -> Void)?
    
    private var albums: [PhotoAlbum]
    private var albumsFetching = [PhotoAlbum]()
    
    private var dataSource: DataSource!
    private var photoToPreview: GooglePhoto?
    
    private let imagedownloader = ImageDownloader()
    
    init?(albums: [PhotoAlbum], coder: NSCoder) {
        self.albums = albums
        super.init(coder: coder)
    }

    @available(*, unavailable, renamed: "init(albums:coder:)")
    required init?(coder: NSCoder) {
        fatalError("Invalid way of decoding this class")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupDataSource()
    }
    
    func reload(albums: [PhotoAlbum]) {
        self.albums = albums
        updateDataSource()
    }
    
    func hide(album: PhotoAlbum) {
        // update albums
        albums.removeAll(where: { $0 == album })
        
        // update data source
        var snapshot = dataSource.snapshot()
        snapshot.deleteSections([album])
                
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func show(album: PhotoAlbum, before beforeAlbum: PhotoAlbum?) {
        // update albums
        if let beforeAlbum, let index = albums.firstIndex(of: beforeAlbum) {
            albums.insert(album, at: index)
        } else {
            albums.append(album)
        }

        // update data source
        var snapshot = dataSource.snapshot()
        
        if let beforeAlbum {
            snapshot.insertSections([album], beforeSection: beforeAlbum)
        } else {
            snapshot.appendSections([album])
        }

        var placeholderPhotos = [Photo]()
        for _ in (album.photos?.count ?? 0) ..< album.photosCount {
            placeholderPhotos.append(PlaceholderPhoto())
        }
        
        snapshot.appendItems(album.photos ?? [], toSection: album)
        snapshot.appendItems(placeholderPhotos, toSection: album)
        
        dataSource.apply(snapshot, animatingDifferences: true)
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
        let album = albums[indexPath.section]
        if !album.photosFetched {
            Task {
                await fetchAllPhotos(forAlbum: album)
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = albums[indexPath.section]
        
        if let photo = album.photos?[indexPath.item] as? GooglePhoto {
            didSelectPhoto?(photo)
        }
    }
}

extension PhotosCollectionViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let albumsToFetch = indexPaths.reduce(into: Set<PhotoAlbum>()) { result, indexPath in
            let album = albums[indexPath.section]
            if !album.photosFetched {
                result.insert(album)
            }
        }
                
        Task {
            // download albums
            for album in albumsToFetch {
                await fetchAllPhotos(forAlbum: album)
            }
            
            // download images
            for indexPath in indexPaths {
                guard
                    let photos = albums[indexPath.section].photos,
                    indexPath.item < photos.count,
                    let photo = photos[indexPath.item] as? GooglePhoto
                else {
                    continue
                }
                
                let thumbnailSize = thumbnailSizeForItem(at: indexPath)
                let urlRequest = URLRequest(url: photo.url(size: thumbnailSize, maintainingAspectRatio: true)!)
                imagedownloader.download(urlRequest)
            }
        }
    }
}

private extension PhotosCollectionViewController {
    
    func setupCollectionView() {
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        
        let layout = PhotosGridCollectionViewLayout()
        layout.photoForIndexPath = { [weak self] indexPath in
            guard let photos = self?.albums[indexPath.section].photos, photos.count > indexPath.item else {
                return PlaceholderPhoto()
            }
            
            return photos[indexPath.item]
        }
        
        collectionView.collectionViewLayout = layout
    }
    
    func setupDataSource() {
        let this = self
        dataSource = DataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.photoCellIdentifier, for: indexPath) as? PhotoCell
            cell?.didLongPress = {
                this.photoToPreview = photo as? GooglePhoto
                Segue.showPhotoPreviewSegue.perform(in: this, sender: nil)
            }
            
            // placeholder photo
            cell?.imageView.image = UIImage(systemName: "photo")
            cell?.imageView.contentMode = .center
            
            if let photo = photo as? GooglePhoto {
                let thumbnailSize = this.thumbnailSizeForItem(at: indexPath)
                
                if let url = photo.url(size: thumbnailSize, maintainingAspectRatio: true) {
                    cell?.imageView.af.imageDownloader = this.imagedownloader
                    // using the imageTransition completion handler, instead of setImage(withURL:) completion, to avoid issues with having the wrong contentMode for the placeholder photo
                    cell?.imageView.af.setImage(withURL: url, imageTransition: .custom(duration: 0, animationOptions: .beginFromCurrentState, animations: { imageView, image in
                        imageView.image = image
                    }, completion: { _ in
                        cell?.imageView.contentMode = .scaleAspectFill
                    }))
                }
            }
            
            return cell
        })
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let album = this.albums[indexPath.section]
                
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.headerViewIdentifier, for: indexPath) as? PhotoAlbumHeaderView
                headerView?.titleNameLabel.text = album.title
                
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
        var updatesSnapshot = NSDiffableDataSourceSnapshot<PhotoAlbum, Photo>()
        for album in albums {
            var placeholderPhotos = [PlaceholderPhoto]()
            for _ in (album.photos?.count ?? 0) ..< album.photosCount {
                placeholderPhotos.append(PlaceholderPhoto())
            }
            
            updatesSnapshot.appendSections([album])
            updatesSnapshot.appendItems(album.photos ?? [], toSection: album)
            updatesSnapshot.appendItems(placeholderPhotos, toSection: album)
        }
        
        dataSource.apply(updatesSnapshot, animatingDifferences: true)
    }
    
    func reloadDataSource(forAlbum album: PhotoAlbum, animatingDifferences: Bool) {
        var snapshot = dataSource.snapshot(for: album)
        
        // avoid race condition - check if album is hidden
        guard !snapshot.items.isEmpty else {
            return
        }
        
        var placeholderPhotos = [PlaceholderPhoto]()
        for _ in (album.photos?.count ?? 0) ..< album.photosCount {
            placeholderPhotos.append(PlaceholderPhoto())
        }
        
        snapshot.deleteAll()
        snapshot.append(album.photos ?? [])
        snapshot.append(placeholderPhotos)
            
        Task {
            dataSource.apply(snapshot, to: album, animatingDifferences: animatingDifferences)
        }
    }
    
    func fetchAllPhotos(forAlbum album: PhotoAlbum) async {
        guard !albumsFetching.contains(where: { $0 == album }) else {
            return
        }
                
        albumsFetching.append(album)
        
        var nextPageToken: String?
        var photos = [GooglePhoto]()
                
        // TODO: Check if Google SDK support for retrieving all photos is better
        repeat {
            let response = await GooglePhotosService.getPhotos(albumId: album.id, pageToken: nextPageToken)
            if let fetchedPhotos = response.photos {
                photos.append(contentsOf: fetchedPhotos)
                album.photos = photos
                                
                reloadDataSource(forAlbum: album, animatingDifferences: false)
            }
                        
            nextPageToken = response.nextPageToken
        } while nextPageToken != nil
        
        albumsFetching.removeAll { $0 == album }
        
        return
    }
    
    func thumbnailSizeForItem(at indexPath: IndexPath) -> CGSize {
        let itemSize = (collectionView.collectionViewLayout as? PhotosGridCollectionViewLayout)?.sizeForItem(at: indexPath)
        let thumbnailSize = (itemSize ?? Constants.cellSize).applying(CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
                
        return thumbnailSize
    }
}
