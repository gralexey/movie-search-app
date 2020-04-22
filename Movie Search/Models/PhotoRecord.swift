//
//  PhotoRecord.swift
//  Movie Search
//
//  Created by Alexey Grabik on 17/04/2020.
//

import UIKit

class PhotoRecord {
    
    var state = State.notLoaded
    var loadedImage: UIImage?
    
    enum State {
        case notLoaded, scheduled, loading, loaded, error, noPicture
    }
    
    var image: UIImage {
        if let loadedImage = loadedImage {
            return loadedImage
        }
        else {
            return UIImage(named: "placeholder")!
        }
    }
}
