//
//  ImageCache.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

class ImageCache {
    
    let cache = NSCache<NSString, UIImage>()
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
    
    func setImage(_ image: UIImage?, for key: String) {
        if let image = image {
            cache.setObject(image, forKey: NSString(string: key))
        }
        else {
            cache.removeObject(forKey: NSString(string: key))
        }
    }
}
