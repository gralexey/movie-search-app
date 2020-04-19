//
//  PhotoRecord.swift
//  Movie Search
//
//  Created by Alexey Grabik on 17/04/2020.
//

import UIKit

class PhotoRecord: NSObject {
    
    var state = State.no
    var loadedImage: UIImage?
    
    enum State {
        case no, scheduled, loading, loaded, error, noPicture
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
