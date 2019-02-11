//
//  FlickerData.swift
//  VirtualTourist
//
//  Created by Mohammed Albaqawi on 1/20/19.
//  Copyright © 2019 Mohd. All rights reserved.
//

import Foundation

struct Flicker : Codable {
    let photos : Photos
    let stat : String
    
}

struct Photos : Codable {
    let perpage : Int
    let photo : [PhotoParse]
    
}

struct PhotoParse : Codable {
    let id : String
    let url_m : String
    
}

