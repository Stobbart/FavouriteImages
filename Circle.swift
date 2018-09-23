//
//  Circle.swift
//  FavouriteImages
//
//  Created by Adam Rikardsen-Smith on 07/07/2018.
//  Copyright © 2018 Adam Rikardsen-Smith. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class Circle: UIView{
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = bounds.width / 2
        layer.opacity = 1.0
    }
    
    
}
