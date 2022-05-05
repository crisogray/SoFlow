//
//  ChoosePhotoCollectionViewController.swift
//  SoFlow
//
//  Created by Ben Gray on 14/10/2015.
//  Copyright © 2015 Graypfruit. All rights reserved.
//

import UIKit
import Photos

class ChoosePhotoCollectionViewController: PhotosCollectionViewController {

    var media = [LibraryPhoto]()
    var firstLoad = true
    var maxSelected: Int!
    var composeCell: ComposeTableViewCell!
    var maxReturnedImages = 27
    
    convenience init(max: Int, cell: ComposeTableViewCell) {
        self.init()
        self.maxSelected = max
        self.title = "Choose Photo or Video"
        self.initCollectionView()
        self.collectionView!.allowsMultipleSelection = true
        self.composeCell = cell
        self.composeCell.choosePhotoViewController = self
    }

    override func viewDidAppear(animated: Bool) {
        if self.firstLoad {
            self.firstLoad = false
            if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.NotDetermined || PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Denied {
                PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                    print("ok")
                    dispatch_async(dispatch_get_main_queue(), {
                        () -> Void in
                        self.fetchPhotos()
                    })
                })
            } else {
                self.fetchPhotos()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if !self.firstLoad {
            if self.collectionView!.indexPathsForSelectedItems() != nil {
                for indexPath in self.collectionView!.indexPathsForSelectedItems()! {
                    let cell = self.collectionView!.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
                    var found = false
                    for m in self.composeCell.media {
                        if (cell.media as! LibraryPhoto).image == m.image {
                            found = true
                        }
                    }
                    if !found {
                        self.collectionView!.deselectItemAtIndexPath(indexPath, animated: false)
                        self.collectionView(self.collectionView!, didDeselectItemAtIndexPath: indexPath)
                    }
                }
            }
        }
    }
    
    func fetchPhotos() {
        self.media = [LibraryPhoto]()
        let imgManager = PHImageManager.defaultManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssetsWithOptions(fetchOptions)
        if fetchResult.count > 0 {
            var max = fetchResult.count
            if fetchResult.count > self.maxReturnedImages {
                max = self.maxReturnedImages
            }
            for i in 0 ..< max {
                imgManager.requestImageForAsset(fetchResult[i] as! PHAsset, targetSize: CGSizeMake(w, w), contentMode: .AspectFill, options: requestOptions, resultHandler: {
                    (image, _) in
                    if fetchResult[i].mediaType! == PHAssetMediaType.Image {
                        self.media.append(LibraryPhoto(image: image!, asset: nil))
                    } else {
                        imgManager.requestAVAssetForVideo(fetchResult[i] as! PHAsset, options: nil, resultHandler: {
                            (asset, mix, dictionary) -> Void in
                            self.media.append(LibraryPhoto(image: image!, asset: asset))
                        })
                    }
                })
            }
            self.loading = false
            self.collectionView!.reloadData()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let media = self.media[indexPath.row]
        cell.setMedia(media)
        cell.del = self
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if collectionView.indexPathsForSelectedItems() != nil {
            if collectionView.indexPathsForSelectedItems()!.count == self.maxSelected {
                return false
            }
        }
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let widthHeight = (w - 4) / 3
        let view = UIView(frame: CGRectMake(0, 0, widthHeight, widthHeight))
        view.backgroundColor = tintColour
        view.alpha = 0.8
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! PhotoCollectionViewCell
        cell.addSubview(view)
        self.composeCell.media.append(cell.media as! LibraryPhoto)
        self.composeCell.updateMedia()
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! PhotoCollectionViewCell
        for view in cell.subviews {
            if view.alpha < 1 {
                view.removeFromSuperview()
            }
        }
        for (i, m) in self.composeCell.media.enumerate() {
            if m.image == (cell.media as! LibraryPhoto).image {
                self.composeCell.media.removeAtIndex(i)
                self.composeCell.updateMedia()
            }
        }
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.media.count
    }

}
