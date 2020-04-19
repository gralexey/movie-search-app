//
//  NetworkAPI.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

protocol NetworkService {
    func search(for movie: String, completionHandler: @escaping ([MovieModel]?, NetworkServiceError?) -> Void)
    func getPoster(_ poster: String, completionHandler: @escaping (UIImage?) -> Void) -> Disposable?
}

enum NetworkServiceError {
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

class NetworkAPI: NSObject, NetworkService {
    
    private let imageCache = ImageCache()
    lazy private var session = URLSession.shared
    
    typealias ImageRequestHandler = (UIImage?) -> Void
    private var imageRequestsHandlers = [URL: [ImageRequestHandler]]()
    
    func search(for movie: String, completionHandler: @escaping ([MovieModel]?, NetworkServiceError?) -> Void) {
        var urlComponents = URLComponents(string: Constants.searchAPIURLString)
        urlComponents?.queryItems = [ URLQueryItem(name: "api_key", value: Constants.APIKey),
                                      URLQueryItem(name: "query", value: movie) ]

        guard let url = urlComponents?.url else {
            completionHandler(nil, NetworkServiceError.constructingRequestError)
            return
        }
        
        query(url) { data, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, NetworkServiceError.badResponse)
                }
                return
            }
            do {
                let page = try JSONDecoder().decode(PageModel.self, from: data)
                let moviesModels = page.results
                DispatchQueue.main.async {
                    completionHandler(moviesModels, nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(nil, NetworkServiceError.parsingError)
                }
            }
        }
    }
    
    func getPoster(_ poster: String, completionHandler: @escaping (UIImage?) -> Void) -> Disposable? {
        assert(Thread.isMainThread)
        
        guard let posterURL = URL(string: Constants.posterAPIURLString)?.appendingPathComponent(poster) else { return nil }
        if let cachedImage = imageCache.getImage(for: posterURL.absoluteString) {
            DispatchQueue.main.async {
                completionHandler(cachedImage)
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
                completionHandler(image)
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
