//
//  DownloadOperation.swift
//  Movie Search
//
//  Created by Alexey Grabik on 17/04/2020.
//

import UIKit

class DownloadOperation: Operation {

    private let movieModel: MovieModel
    private let networkService: NetworkService
    private let finishBlock: () -> Void
    var downloadTaskDisposal: Disposable?
    let indexPath: IndexPath
    
    private let semaphore = DispatchSemaphore(value: 0)
    
    init(indexPath: IndexPath,
         movieModel: MovieModel,
         networkService: NetworkService,
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
                self.downloadTaskDisposal = self.networkService.getPoster(posterPath) { [weak self] image in
                    guard let self = self, !self.isCancelled else { return }
                    self.movieModel.photoRecord.loadedImage = image
                    self.movieModel.photoRecord.state = (image != nil) ? .loaded : .error
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
            movieModel.photoRecord.state = .no
        }
        downloadTaskDisposal?.dispose()
    }
}
