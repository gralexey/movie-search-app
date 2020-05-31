//
//  MovieModel.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

struct MovieModel: Decodable {
    let title: String
    let overview: String
    let posterPath: String?
    var photoRecord = PhotoRecord()
    
    private enum CodingKeys : String, CodingKey {
        case title, overview, posterPath = "poster_path"
    }
    
    var isPhotoReadyForDownload: Bool {
        return photoRecord.state == .notLoaded && posterPath != nil
    }
}
