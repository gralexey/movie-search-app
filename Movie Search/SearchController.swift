//
//  SearchController.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

enum SearchStatus {
    case error(String), nothingRequested, noResult, success
}

class SearchController: NSObject {
    
    private let networkService: NetworkService
    
    private var moviesModels = [MovieModel]() {
        didSet {
            downloadQueue.cancelAllOperations()
        }
    }
    private let downloadQueue = OperationQueue()
    
    var searchPerformedCallback: ((SearchStatus) -> Void)?
    
    init(networkService: NetworkService = NetworkAPI()) {
        self.networkService = networkService
        self.downloadQueue.maxConcurrentOperationCount = Constants.maxConcurrentOperationCount
        super.init()
    }
    
    func search(for movieTitle: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self) 
        perform(#selector(self.performSearch(_:)),
                with: movieTitle,
                afterDelay: Constants.searchThrottleDelay)
    }
}

private extension SearchController {
    
    class func status(with networkError: NetworkServiceError?) -> SearchStatus? {
        guard let error = networkError else { return nil }
        switch error {
        case .badResponse:
            return .error("Bad response")
        case .parsingError:
            return .error("Parsing error")
        case .constructingRequestError:
            return .error("Constructing request error")
        }
    }
    
    @objc
    func performSearch(_ movieTitle: String) {
        if movieTitle.count > 0 {
            networkService.search(for: movieTitle) { moviesModels, error in
                self.moviesModels = moviesModels ?? []
                if let status = Self.status(with: error) {
                    self.searchPerformedCallback?(status)
                }
                else if self.moviesModels.isEmpty {
                    self.searchPerformedCallback?(.noResult)
                }
                else {
                    self.searchPerformedCallback?(.success)
                }
            }
        }
        else {
            moviesModels = []
            searchPerformedCallback?(.nothingRequested)
        }
    }
    
    func tryToLoadPhoto(for indexPath: IndexPath, in tableView: UITableView) {
        let movieModel = moviesModels[indexPath.row]
        guard movieModel.isPhotoReadyForDownload else { return }
        movieModel.photoRecord.state = .scheduled
        
        let downloadOperation = DownloadOperation(indexPath: indexPath,
                                                  movieModel: movieModel,
                                                  networkService: networkService) {
             tableView.reloadRows(at: [indexPath], with: .fade)
        }
        downloadQueue.addOperation(downloadOperation)
    }
}

extension SearchController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return moviesModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MovieCell.cellIdentifier) as? MovieCell
        else {
            fatalError()
        }
        
        let movieModel = moviesModels[indexPath.row]
        cell.fill(with: movieModel)
        tryToLoadPhoto(for: indexPath, in: tableView)
        return cell
    }
}

extension SearchController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { tryToLoadPhoto(for: $0, in: tableView) }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        downloadQueue.operations
            .compactMap { $0 as? DownloadOperation }
            .filter { indexPaths.contains($0.indexPath) }
            .forEach { $0.cancel() }
    }
}
