//
//  ViewController.swift
//  FavouriteImages
//
//  Created by Adam Rikardsen-Smith on 01/07/2018.
//  Copyright © 2018 Adam Rikardsen-Smith. All rights reserved.
//

import UIKit
import SwiftyJSON

enum OpacityFade: Float {
    case hide = 0.0
    case show = 1.0
}

class ViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    var searchResults: [SearchResult] = []
    var saveSearchResults: [SearchResult] = []
    let imageCache = NSCache<SearchResult, UIImage>()
    var circlePath = UIBezierPath()
    let animation = CAKeyframeAnimation()
    var storedImageData: [Data] = []
    let validCharacters: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", ""]
    @IBOutlet weak var theCircle: Circle!
    let imageCornerRadius: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStoredImages()
        imageCollectionView.dragDelegate = self
        imageCollectionView.dropDelegate = self
        circlePath = UIBezierPath(ovalIn: CGRect(x: view.frame.width / 4 + theCircle.frame.width, y: view.frame.height / 2 - theCircle.frame.width, width: view.frame.width / 4, height: view.frame.width / 4))
        animation.keyPath = "position"
        animation.repeatCount = .infinity
        animation.duration = 0.75
        animation.path = circlePath.cgPath
        animation.calculationMode = kCAAnimationPaced
        self.theCircle.layer.add(animation, forKey: "move image along bezier path")
        imageCollectionView.dragInteractionEnabled = true
        searchField.delegate = self
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Image Management
    
    @IBAction func searchForImages(_ sender: Any) {
        
        searchField.resignFirstResponder()
        searchResults.removeAll()
        saveSearchResults.removeAll()
        imageCache.removeAllObjects()
        changeCircleOpacity(opacityFade: .show)
        
        DownloadManager.getInstance().searchForImages(query: searchField.text ?? "") { (json: JSON) in
            
            if self.returnedNoConnection(json: json){
                return
            }
            
            if let results = json["hits"].array {
                for entry in results {
                    let searchResult: SearchResult = SearchResult(json: entry)
                    self.searchResults.append(searchResult)
                    self.cacheImage(searchResult: searchResult)
                }
            }
            
            self.loadStoredImages()
            self.reloadCollectionView()
            self.changeCircleOpacity(opacityFade: .hide)
        }

    }
    
    func returnedNoConnection(json: JSON) -> Bool{
        if json[0] == "No Connection"{
            self.changeCircleOpacity(opacityFade: .hide)
            showNoConnectionAlert()
            return true
        }
        return false
    }
    
    func showNoConnectionAlert(){
        let noConnectionAlert = UIAlertController(title: "No Internet Connection", message: "Please connect to the internet to download images", preferredStyle: .alert)
        noConnectionAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: {(_) in }))
        
        present(noConnectionAlert, animated: true, completion: nil)
    }

    func cacheImage(searchResult: SearchResult){
        let url = URL(string:searchResult.imageURLString ??  "")
        if let data = NSData(contentsOf: url ?? URL(fileURLWithPath: "")) {
            self.imageCache.setObject(UIImage(data: data as Data)!, forKey: searchResult)
        }
    }

    // MARK: Animation
    
    func changeCircleOpacity(opacityFade: OpacityFade){
        DispatchQueue.main.async {
            UIViewPropertyAnimator(duration: 1, curve: .easeIn) {
                switch opacityFade{
                    case .hide: self.theCircle.layer.opacity = 0
                    self.imageCollectionView.layer.opacity = 1
                    case .show: self.theCircle.layer.opacity = 1
                    self.imageCollectionView.layer.opacity = 0
                }
                }.startAnimation()
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resignFirstResponder()
    }
    
}

// MARK: Drag and Drop

extension ViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: NSString(string: String(indexPath.row)))
        let dragItem = UIDragItem(itemProvider: itemProvider)

        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else {
            return
        }
        
        let item = coordinator.items.first
        
        if searchResults.count < 2 && item?.sourceIndexPath?.section == 0{
            return
        }
        if saveSearchResults.count < 2 && item?.sourceIndexPath?.section == 1{
            return
        }

        switch coordinator.proposal.operation {
            
        case .move:
        if coordinator.destinationIndexPath?.section == 0 && item?.sourceIndexPath?.section == 0{
            self.searchResults.insert(self.searchResults.remove(at: (item?.sourceIndexPath?.row) ?? 0), at: destinationIndexPath.row)
        }
        if coordinator.destinationIndexPath?.section == 1 && item?.sourceIndexPath?.section == 0{
            self.saveSearchResults.insert(self.searchResults.remove(at: (item?.sourceIndexPath?.row) ?? 0), at: destinationIndexPath.row)
        }
        if coordinator.destinationIndexPath?.section == 0 && item?.sourceIndexPath?.section == 1{
            self.searchResults.insert(self.saveSearchResults.remove(at: (item?.sourceIndexPath?.row) ?? 0), at: destinationIndexPath.row)
        }
        if coordinator.destinationIndexPath?.section == 1 && item?.sourceIndexPath?.section == 1{
            self.saveSearchResults.insert(self.saveSearchResults.remove(at: (item?.sourceIndexPath?.row) ?? 0), at: destinationIndexPath.row)
        }
        
            imageCollectionView.performBatchUpdates({
                imageCollectionView.deleteItems(at: [(item?.sourceIndexPath)!])
                imageCollectionView.insertItems(at: [destinationIndexPath])
            })
            
                coordinator.drop((item?.dragItem)!, toItemAt: destinationIndexPath)
        
        default: return
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel, intent: .insertAtDestinationIndexPath)
        }
    }
    
}

// MARK: Collection View Delegate

extension ViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, view.frame.height / 20, 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return searchResults.count
        case 1:
            return saveSearchResults.count
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let searchCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCell", for: indexPath) as! SearchCell
        
        searchCell.imageView.clipsToBounds = true
        searchCell.imageView.layer.cornerRadius = imageCornerRadius
        searchCell.layer.cornerRadius = imageCornerRadius
        if indexPath.section == 1{
            searchCell.imageView.image = imageCache.object(forKey: saveSearchResults[indexPath.row])
        } else{
            searchCell.imageView.image = imageCache.object(forKey: searchResults[indexPath.row])
        }
        return searchCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if cell?.frame.height == collectionView.frame.width{
            collectionView.reloadData()
        } else {
            let newCellYPosition: CGFloat = collectionView.contentOffset.y + collectionView.frame.height / 2 - collectionView.frame.width / 2
            cell?.frame = CGRect(x: 0, y: newCellYPosition , width: collectionView.frame.width, height: collectionView.frame.width)
            collectionView.bringSubview(toFront: cell!)
        }

        resignFirstResponder()
    }
    
    func reloadCollectionView(){
        DispatchQueue.main.async {
            self.imageCollectionView.reloadData()
            self.scrollToTop()
        }
    }
    
    func scrollToTop(){
        if self.searchResults.count > 0{
            self.imageCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    
    // MARK: Storing images methods
    
    func storeImagesLocally(){
        if saveSearchResults.count > 1{
            for i in 0...saveSearchResults.count - 2{
                let dataToSave = UIImagePNGRepresentation(imageCache.object(forKey: saveSearchResults[i]) ?? UIImage()) ?? Data()
                if !storedImageData.contains(dataToSave){
                    storedImageData.append(dataToSave)
                    saveImageToCameraRoll(searchResult: saveSearchResults[i])
                }

            }
        
        let defaults = UserDefaults.standard
            defaults.set(storedImageData, forKey: "SavedImages")
        }
        
    }

    @IBAction func exportImages(){
        
        let exportAlert = UIAlertController(title: "Export Images", message: "Are you sure you want to export to the camera roll?", preferredStyle: .alert)
        exportAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(_) in
            self.storeImagesLocally()
        }))
        
        exportAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(_) in }))
        
        present(exportAlert, animated: true, completion: nil)
    }
    
    func saveImageToCameraRoll(searchResult: SearchResult){
        UIImageWriteToSavedPhotosAlbum(imageCache.object(forKey: searchResult)!, nil, nil, nil)
    }
    
    
    
    func loadStoredImages(){
        let defaults = UserDefaults.standard
        storedImageData = (defaults.array(forKey: "SavedImages") as? [Data]) ?? []
        
        for imageData in storedImageData{
            let saveSearchResult: SearchResult = SearchResult(json: [])
            saveSearchResults.append(saveSearchResult)
            self.imageCache.setObject(UIImage(data: imageData)!, forKey: saveSearchResult)
        }
        saveSearchResults.append(SearchResult(json: []))
    }

}


// MARK: Collection View Layout

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    @IBAction func changeLayout() {
        if CustomLayout.numberOfColumns == 1{
            CustomLayout.numberOfColumns = 5
        } else{
            CustomLayout.numberOfColumns = 1
        }
        imageCollectionView?.reloadData()
    }
}

// MARK: UITextFieldDelegate

extension ViewController: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if validCharacters.contains(string){
            return true
        } else{
            return false
        }
        
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
 
    
}


