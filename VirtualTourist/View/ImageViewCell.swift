//
//  ImageViewCell.swift
//  VirtualTourist
//
//  Created by Marcos Vinicius Goncalves Contente on 27/02/19.
//  Copyright © 2019 Marcos Vinicius Goncalves Contente. All rights reserved.
//

import Foundation
import UIKit

class ImageViewCell: UICollectionViewCell {
    
    var imageUrl: String = ""
    @IBOutlet weak var imageViewCell: UIImageView!
    @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView!
    
}
