//
//  FilterViewController.swift
//  ExchangeAGram
//
//  Created by Tony Morales on 10/26/14.
//  Copyright (c) 2014 Tony Morales. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    
    var thisFeedItem: FeedItem!
    
    var collectionView: UICollectionView!
    
    let kIntensity = 0.7
    
    var context: CIContext = CIContext(options: nil)
    
    var filters: [CIFilter] = []
    
    let placeholderImage = UIImage(named: "Placeholder")
    
    let tmp = NSTemporaryDirectory()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        view.addSubview(collectionView)
        
        filters = photoFilters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
        

        
        cell.imageView.image = placeholderImage
        
        let filterQueue: dispatch_queue_t = dispatch_queue_create("filter queue", nil)
        
        dispatch_async(filterQueue, { () -> Void in
            
            let filterImage = self.getCachedImage(indexPath.row)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                cell.imageView.image = filterImage
                
            })
        })
        

        
        return cell
    }
    
    
    // UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        createUIAlertController(indexPath)
    }
    
    
    
    // Helper Function
    
    func photoFilters () -> [CIFilter] {
        
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)

        
        // The code below is currently throwing an error about not needing z/w/forKey arguments, rather than dick around i'm just excluding that filter since i don't give a shit about colorClamps
//        let colorClamp = CIFilter(name: "CIColorClamp")
//        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9, forKey: "inputMaxComponents"))
//        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2, forKey: "inputMinComponents"))
        
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia,
            //colorClamp, 
            composite, vignette]
    }

    
    func filteredImageFromImage (imageData: NSData, filter: CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage: CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage: CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: UIImageOrientation.Up)
        
        return finalImage!
        
    }
    
    
    // UIAlertController Helper Functions
    
    func createUIAlertController (indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "Please add a caption, bitch", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add Caption!"
            textField.secureTextEntry = false
        }
    
        
        let textField = alert.textFields![0] as UITextField
        
        let photoAction = UIAlertAction(title: "Post Photo to Facebook with Caption", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            
            self.shareToFacebook(indexPath)
            
            var text = textField.text
            
            self.saveFilterToCoreData(indexPath, caption: text)
        }
        
        alert.addAction(photoAction)
        
        
        let saveFilterAction = UIAlertAction(title: "Save Filter without Posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            var text = textField.text
            
            self.saveFilterToCoreData(indexPath, caption: text)
        }
        
        alert.addAction(saveFilterAction)
        
        let cancelAction = UIAlertAction(title: "Select Another Filter", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            
        }
        
        alert.addAction(cancelAction)
        
        
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func saveFilterToCoreData (indexPath: NSIndexPath, caption: String) {
        let filterImage = filteredImageFromImage(thisFeedItem.image, filter: filters[indexPath.row])
        
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        
        thisFeedItem.image = imageData
        
        let thumbnailData = UIImageJPEGRepresentation(filterImage, 0.1)
        thisFeedItem.thumbnail = thumbnailData
        
        thisFeedItem.caption = caption
        thisFeedItem.filtered = true
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        
        navigationController?.popViewControllerAnimated(true)

    }
    
    
    func shareToFacebook (indexPath: NSIndexPath) {
        let filterImage = filteredImageFromImage(thisFeedItem.image, filter: filters[indexPath.row])
        
        
        let photos:NSArray = [filterImage]
        var params = FBPhotoParams()
        params.photos = photos
        
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
            if (result? != nil) {
                println(result)
            } else {
                println(error)
            }
        }
    }
    
    
    // Caching Functions
    
    func cacheImage (imageNumber: Int) {
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            
            let data = thisFeedItem.thumbnail
            let filter = filters[imageNumber]
            let image = filteredImageFromImage(data, filter: filter)
            UIImageJPEGRepresentation(image, 1.0).writeToFile(uniquePath, atomically: true)
        }
        
    }
    
    func getCachedImage (imageNumber: Int) -> UIImage {
        let fileName = "\(thisFeedItem.uniqueID)\(imageNumber)"
        let uniquePath = tmp.stringByAppendingPathComponent(fileName)
        
        var image: UIImage
        
        if NSFileManager.defaultManager().fileExistsAtPath(uniquePath) {
            image = UIImage(contentsOfFile: uniquePath)!
            
            
// Below four lines of commented code to be used if the photos aren't displaying properly rotated on actual devices
//            var returnedImage = UIImage(contentsOfFile: uniquePath)!
//            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
        } else {
            cacheImage(imageNumber)
            image = UIImage(contentsOfFile: uniquePath)!
//            var returnedImage = UIImage(contentsOfFile: uniquePath)!
//            image = UIImage(CGImage: returnedImage.CGImage, scale: 1.0, orientation: UIImageOrientation.Right)!
        }
        
        return image
        
        
    }
    
    
    
    
    
    
    
    
    

}