//
//  MovieCell.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

class MovieCell: UITableViewCell {
    
    @IBOutlet var posterView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var overviewLabel: UILabel!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    static let cellIdentifier = "MovieCell"

    override func prepareForReuse() {
        super.prepareForReuse()
        posterView.image = nil
        titleLabel.text = nil
        overviewLabel.text = nil
    }

    func fill(with movieModel: MovieModel) {
        if movieModel.photoRecord.state == .loading {
            spinner.startAnimating()
        }
        else {
            spinner.stopAnimating()
        }
        titleLabel.text = movieModel.title
        overviewLabel.text = movieModel.overview
        posterView.image = movieModel.photoRecord.image
        posterView.contentMode = movieModel.photoRecord.state == .loaded ? .scaleAspectFit : .scaleAspectFill
    }
}
