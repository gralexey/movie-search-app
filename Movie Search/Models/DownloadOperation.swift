//
//  DownloadOperation.swift
//  Movie Search
//
//  Created by Alexey Grabik on 17/04/2020.
//

import UIKit

class DownloadOperation: Operation {

    private let movieModel: MovieModel
    private let networkService: NetworkServiceProtocol
    private let finishBlock: () -> Void
    var downloadTaskDisposal: Disposable?
    let indexPath: IndexPath
    
    private let semaphore = DispatchSemaphore(value: 0)
    
    init(indexPath: IndexPath,
         movieModel: MovieModel,
         networkService: NetworkServiceProtocol,
         finishBlock: @escaping () -> Void) {
        self.indexPath = indexPath
        self.movieModel = movieModel
        self.networkService = networkService
        self.finishBlock = finishBlock
        super.init()
    }
    
    override func main() {
        guard !isCancelled else {
            return
        }
        
        movieModel.photoRecord.state = .loading
        
        if let posterPath = movieModel.posterPath {
            DispatchQueue.main.async {
                self.downloadTaskDisposal = self.networkService.getPoster(posterPath) { [weak self] result in
                    guard let self = self, !self.isCancelled else { return }
                    switch result {
                    case .success(let image):
                        self.movieModel.photoRecord.loadedImage = image
                        self.movieModel.photoRecord.state = .loaded
                    case .failure(_):
                        self.movieModel.photoRecord.state = .error
                    }
                    self.semaphore.signal()
                    self.finishBlock()
                }
            }
        }
        else {
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    override func cancel() {
        super.cancel()
        semaphore.signal()
        let state = movieModel.photoRecord.state
        if state != .loaded && state != .error {
            movieModel.photoRecord.state = .notLoaded
        }
        downloadTaskDisposal?.dispose()
    }
}
