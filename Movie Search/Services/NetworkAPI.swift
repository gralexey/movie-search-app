//
//  NetworkAPI.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

private let searchAPIURLString = "https://api.themoviedb.org/3/search/movie"
private let APIKey = "2a61185ef6a27f400fd92820ad9e8537"
private let posterAPIURLString = "https://image.tmdb.org/t/p/w600_and_h900_bestv2"

typealias MoviesRequestResult = Result<[MovieModel], NetworkServiceError>
typealias ImageRequestResult = Result<UIImage, NetworkServiceError>

protocol NetworkServiceProtocol {
    func search(forMovie movie: String, completionHandler: @escaping (MoviesRequestResult) -> Void)
    func getPoster(_ poster: String, completionHandler: @escaping (ImageRequestResult) -> Void) -> Disposable?
}

enum NetworkServiceError: Error {
    case badResponse, parsingError, constructingRequestError
}

class Disposable {
    private let cancelHandler: () -> Void
    
    init(_ cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }
    
    func dispose() {
        cancelHandler()
    }
}

class NetworkAPI: NetworkServiceProtocol {
    
    private let imageCache = ImageCache()
    lazy private var session = URLSession.shared

    typealias ImageRequestHandler = (ImageRequestResult) -> Void
    private var imageRequestsHandlers = [URL: [ImageRequestHandler]]()
    
    func search(forMovie movie: String, completionHandler: @escaping (MoviesRequestResult) -> Void) {
        var urlComponents = URLComponents(string: searchAPIURLString)
        urlComponents?.queryItems = [ URLQueryItem(name: "api_key", value: APIKey),
                                      URLQueryItem(name: "query", value: movie) ]

        guard let url = urlComponents?.url else {
            completionHandler(Result.failure(NetworkServiceError.constructingRequestError))
            return
        }
        
        query(url) { data, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(NetworkServiceError.badResponse))
                }
                return
            }
            do {
                let page = try JSONDecoder().decode(PageModel.self, from: data)
                let moviesModels = page.results
                DispatchQueue.main.async {
                    completionHandler(Result.success(moviesModels))
                }
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(Result.failure(NetworkServiceError.parsingError))
                }
            }
        }
    }
    
    func getPoster(_ poster: String, completionHandler: @escaping (ImageRequestResult) -> Void) -> Disposable? {
        assert(Thread.isMainThread)
        
        guard let posterURL = URL(string: posterAPIURLString)?.appendingPathComponent(poster) else { return nil }
        if let cachedImage = imageCache.getImage(for: posterURL.absoluteString) {
            DispatchQueue.main.async {
                completionHandler(Result.success(cachedImage))
            }
            return nil
        }
        else {
            let isRequestInProcess = imageRequestsHandlers[posterURL, default: []].count > 0
            imageRequestsHandlers[posterURL, default: []].append(completionHandler)
            
            if !isRequestInProcess {
                return query(posterURL) { [weak self] data, error in
                    self?.resolveAllRequests(for: posterURL, with: data)
                }
            }
        }
        return nil
    }
}

private extension NetworkAPI {
    
    func resolveAllRequests(for url: URL, with data: Data?) {
        assert(Thread.isMainThread)
        
        let image = data == nil ? nil : UIImage(data: data!)
        imageCache.setImage(image, for: url.absoluteString)
        imageRequestsHandlers[url]?.forEach({ completionHandler in
            DispatchQueue.main.async {
                if let image = image {
                    completionHandler(Result.success(image))
                }
                else {
                    completionHandler(Result.failure(NetworkServiceError.badResponse))
                }
            }
        })
        imageRequestsHandlers[url] = nil
    }
    
    @discardableResult
    func query(_ url: URL, completionHandler: @escaping (Data?, Error?) -> Void) -> Disposable {
        assert(Thread.isMainThread)
        let request = URLRequest(url: url)

        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completionHandler(data, error)
            }
        }
        task.resume()
        return Disposable {
            task.cancel()
        }
    }
}
