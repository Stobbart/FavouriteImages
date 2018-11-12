//
//  DownloadManager.swift
//  FavouriteImages
//
//  Created by Adam Rikardsen-Smith on 01/07/2018.
//  Copyright © 2018 Adam Rikardsen-Smith. All rights reserved.
//

import Foundation
import SwiftyJSON
import ReachabilitySwift

class DownloadManager: NSObject {
    
    static var reachability: Reachability?
    let imageType = "photo"
    let apiKey = "9433532-ee9ee4b231c8a350a7212e041"
    let resultsPerPage: Int = 60
    
    static var downloadManager: DownloadManager!
    
    static func getInstance() -> DownloadManager {
        if(downloadManager == nil) {
            downloadManager = DownloadManager()
        }
        reachability =  Reachability()
        return downloadManager
    }
    
    func searchForImages(query: String, onCompletion: @escaping (JSON) -> Void) {
        if (DownloadManager.reachability?.isReachable) ?? false{
            getSearchImages(query: query, onCompletion: { json, err in
                onCompletion(json as JSON)
            })
        } else{
            onCompletion(["No Connection"])
        }

    }
    
    
    
    private func getSearchImages(query: String, onCompletion: @escaping (JSON, NSError?) -> Void) {
        
        // create the search url
        let finalUrl = URL(string: "https://pixabay.com/api/?key=" + apiKey + "&q=" + query + "&image_type=" + imageType + "&per_page=" + String(resultsPerPage))
        
        let request = NSMutableURLRequest(url: finalUrl!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        // request the search results, callback to the view controller when request is complete
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let jsonData = data {
                do {
                    let json:JSON = try JSON(data: jsonData)
                    onCompletion(json, error as NSError?)
                } catch {
                    print("error in converting json data from image search response")

                    onCompletion([], error as NSError?)
                }
            } else {
                onCompletion(JSON.null, error as NSError?)
            }
        })
        task.resume()
}
 
}
