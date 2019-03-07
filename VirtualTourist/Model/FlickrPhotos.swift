//
//  FlickrPhotos.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 28/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation
import CoreData

struct FlickrPhotos: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_m"
        case title
    }
}
