//
//  ApiConstants.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 25/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation

extension ApiServices {
    
    struct Constants {
        
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
            static let SearchBBoxHalfWidth = 0.2
            static let SearchBBoxHalfHeight = 0.2
            static let SearchLatRange = (-90.0, 90.0)
            static let SearchLonRange = (-180.0, 180.0)
        }
        
        struct FlickrParameterKeys {
            static let Page = "page"
            static let Method = "method"
            static let Extras = "extras"
            static let APIKey = "api_key"
            static let Format = "format"
            static let Accuracy = "accuracy"
            static let GalleryID = "gallery_id"
            static let SafeSearch = "safe_search"
            static let BoundingBox = "bbox"
            static let PhotosPerPage = "per_page"
            static let NoJSONCallback = "nojsoncallback"
        }
        
        struct FlickrParameterValues {
            static let APIKey = "d8f1c926d8f9f35412e309df288d33ba"
            static let MediumURL = "url_m"
            static let SearchMethod = "flickr.photos.search"
            static let UseSafeSearch = "1"
            static let PhotosPerPage = 20
            static let ResponseFormat = "json"
            static let AccuracyCityLevel = "11"
            static let AccuracyStreetLevel = "16"
            static let DisableJSONCallback = "1"
        }
    }
}
