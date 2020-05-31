//
//  MockNetworkAPI.swift
//  Movie Search
//
//  Created by Alexey Grabik on 19/04/2020.
//

import UIKit

class MockNetworkAPI: NetworkServiceProtocol {
    
    func search(forMovie movie: String, completionHandler: @escaping (MoviesRequestResult) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let movieModel1 = MovieModel(title: "Test title 1",
                                         overview: "Test overview 1",
                                         posterPath: "/r4DIx2F0lRlMPNeKQXz9VE5mLAQ.jpg")
            let movieModel2 = MovieModel(title: "Test title 2",
                                         overview: "Test overview 2",
                                         posterPath: "/epTCHVcyLkT8Aqt08Ki3PWC2sUh.jpg")
            completionHandler(Result.success([movieModel1, movieModel2]))
        }
    }
    
    func getPoster(_ poster: String, completionHandler: @escaping (ImageRequestResult) -> Void) -> Disposable? {
        guard let image = UIImage(named: "placeholder") else { return nil }
        completionHandler(Result.success(image))
        return nil
    }
}
