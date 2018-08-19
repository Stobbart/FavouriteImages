//
//  SearchResult.swift
//  FavouriteImages
//
//  Created by Adam Rikardsen-Smith on 01/07/2018.
//  Copyright © 2018 Adam Rikardsen-Smith. All rights reserved.
//

import Foundation
import SwiftyJSON

class SearchResult {
    var imageURLString: String!
    var imageLikes: Int!
    
    required init(json: JSON) {
        imageURLString = json["largeImageURL"].stringValue
        imageLikes = json["likes"].intValue
    }
}
