//
//  SearchController.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

private let searchThrottleDelay: TimeInterval = 0.5
private let maxConcurrentOperationCount = 5

enum SearchStatus {
    case error(String), nothingRequested, noResult, success
}

class SearchController: NSObject {
    
    private let networkService: NetworkServiceProtocol
    
    private var moviesModels = [MovieModel]() {
        didSet {
            downloadQueue.cancelAllOperations()
        }
    }
    private let downloadQueue = OperationQueue()
    
    var searchPerformedCallback: ((SearchStatus) -> Void)?
    
    init(networkService: NetworkServiceProtocol = NetworkAPI()) {
        self.networkService = networkService
        self.downloadQueue.maxConcurrentOperationCount = maxConcurrentOperationCount
        super.init()
    }
    
    func search(forMovie movieTitle: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self) 
        perform(#selector(self.performSearch(_:)),
                with: movieTitle,
                afterDelay: searchThrottleDelay)
    }
}

private extension SearchController {
    
    @objc
    func performSearch(_ movieTitle: String) {
        if !movieTitle.isEmpty {
            networkService.search(forMovie: movieTitle) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let moviesModels):
                    self.moviesModels = moviesModels
                    self.searchPerformedCallback?(moviesModels.isEmpty ? .noResult : .success)
                case .failure(let error):
                    self.searchPerformedCallback?(error.status())
                }
            }
        }
        else {
            moviesModels = []
            searchPerformedCallback?(.nothingRequested)
        }
    }
    
    func tryToLoadPhoto(for indexPath: IndexPath, in tableView: UITableView) {
        guard indexPath.row < moviesModels.count else { return }
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
            assertionFailure("error dequeuing cell")
            return UITableViewCell()
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

private extension NetworkServiceError {
    
    func status() -> SearchStatus {
        switch self {
        case .badResponse:
            return .error("Bad response")
        case .parsingError:
            return .error("Parsing error")
        case .constructingRequestError:
            return .error("Constructing request error")
        }
    }
}
