//
//  ToggleAlbumsVisibilityViewController.swift
//  EventDigest
//
//  Created by Alex Bumbu on 18.03.2024.
//

import UIKit

private typealias DataSource = UITableViewDiffableDataSource<Int, PhotoAlbum>

class ToggleAlbumsVisibilityViewController: UITableViewController {
    
    private enum Constants {
        static let albumCellIdentifier = "albumCell"
    }
    
    var didHideAlbum: ((PhotoAlbum) -> ())?
    var didShowAlbum: ((PhotoAlbum) -> ())?
    
    private var albums = [PhotoAlbum]()
    private var hiddenAlbums = [PhotoAlbum]()
    private var dataSource: DataSource!
    
    init?(albums: [PhotoAlbum], hiddenAlbums: [PhotoAlbum], coder: NSCoder) {
        self.albums = albums
        self.hiddenAlbums = hiddenAlbums
        super.init(coder: coder)
    }

    @available(*, unavailable, renamed: "init(albums:hiddenAlbums:coder:)")
    required init?(coder: NSCoder) {
        fatalError("Invalid way of decoding this class")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataSource()
        updateDataSource()
    }
}

extension ToggleAlbumsVisibilityViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let album = albums[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! AlbumCell
        
        if hiddenAlbums.contains(where: { $0 == album}) {
            cell.albumIsVisible = false
            hiddenAlbums.removeAll(where: { $0 == album})
            
            didShowAlbum?(album)
        } else {
            cell.albumIsVisible = true
            hiddenAlbums.append(album)
            
            didHideAlbum?(album)
        }
    }
}

private extension ToggleAlbumsVisibilityViewController {
    
    func setupDataSource() {
        let this = self
        
        dataSource = DataSource(tableView: tableView) {tableView, indexPath, album in
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.albumCellIdentifier) as? AlbumCell
            cell?.titleLabel.text = album.title
            
            if this.hiddenAlbums.contains(where: { $0 == album}) {
                cell?.albumIsVisible = true
            }
            
            return cell
        }
    }
    
    func updateDataSource() {
        var updatesSnapshot = NSDiffableDataSourceSnapshot<Int, PhotoAlbum>()
        updatesSnapshot.appendSections([0])
        updatesSnapshot.appendItems(albums)
        
        dataSource.apply(updatesSnapshot, animatingDifferences: true)
    }
}
