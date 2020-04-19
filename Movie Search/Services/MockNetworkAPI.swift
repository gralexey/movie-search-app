//
//  MockNetworkAPI.swift
//  Movie Search
//
//  Created by Alexey Grabik on 19/04/2020.
//

import UIKit

class MockNetworkAPI: NetworkService {
    
    func search(for movie: String, completionHandler: @escaping ([MovieModel]?, NetworkServiceError?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            let movieModel1 = MovieModel(title: "Test title 1",
                                         overview: "Test overview 1",
                                         posterPath: "/r4DIx2F0lRlMPNeKQXz9VE5mLAQ.jpg")
            let movieModel2 = MovieModel(title: "Test title 2",
                                         overview: "Test overview 2",
                                         posterPath: "/epTCHVcyLkT8Aqt08Ki3PWC2sUh.jpg")
            completionHandler([movieModel1, movieModel2], nil)
        }
    }
    
    func getPoster(_ poster: String, completionHandler: @escaping (UIImage?) -> Void) -> Disposable? {
        completionHandler(UIImage(named: "placeholder"))
        return nil
    }
}
