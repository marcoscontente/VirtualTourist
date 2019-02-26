//
//  ApiConstants.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 25/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation

extension ApiServices {
    
    // MARK: Types
    enum API {
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let path = "/services/rest"
    }
    
    enum Methods {
        static let photosSearch = "flickr.photos.search"
    }
    
    enum ParameterKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let galleryID = "gallery_id"
        static let extras = "extras"
        static let format = "format"
        static let noJsonCallback = "nojsoncallback"
        static let text = "text"
        static let boundingBox = "bbox"
    }
    
    enum ParameterDefaultValues {
        static let format = "json"
        static let noJsonCallback = "1"
        static let mediumUrl = "url_m"
        static let apiKey = "d8f1c926d8f9f35412e309df288d33ba"
    }
}
