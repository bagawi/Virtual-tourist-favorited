//
//  Constants.swift
//  VirtualTourist
//
//  Created by Mohammed Albaqawi on 1/20/19.
//  Copyright © 2019 Mohd. All rights reserved.
//

import Foundation

extension Api {
    
    struct Constants {
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
            
            static let SearchBBoxHalfWidth = 1.0
            static let SearchBBoxHalfHeight = 1.0
            static let SearchLatRange = (-90.0, 90.0)
            static let SearchLonRange = (-180.0, 180.0)
        }
        
        // MARK: Flickr Parameter Keys
        struct FlickrParameterKeys {
            static let Method = "method"
            static let APIKey = "api_key"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let SafeSearch = "safe_search"
            static let BoundingBox = "bbox"
            static let PhotosPerPage = "per_page"
            static let Page = "page"
        }
        
        // MARK: Flickr Parameter Values
        struct FlickrParameterValues {
            static let SearchMethod = "flickr.photos.search"
            static let APIKey = "9ce8a44289f0aa5f2c8e7eb84846ab27"
            static let ResponseFormat = "json"
            static let DisableJSONCallback = "1"
            static let PhotosPerPage = "18"
            static let MediumURL = "url_m"
            static let UseSafeSearch = "1"
           // var Page = 1
        }

    }
}
