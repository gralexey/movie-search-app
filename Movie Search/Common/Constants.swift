//
//  Constants.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

struct Constants {
    static let searchAPIURLString = "https://api.themoviedb.org/3/search/movie"
    static let APIKey = "2a61185ef6a27f400fd92820ad9e8537"
    static let posterAPIURLString = "https://image.tmdb.org/t/p/w600_and_h900_bestv2"
    static let searchThrottleDelay: TimeInterval = 0.5
    static let maxConcurrentOperationCount = 5
}
