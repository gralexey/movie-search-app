//
//  MovieSearchViewController.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

class MovieSearchViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var spinner: UIActivityIndicatorView!
    let searchController = SearchController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchCallback()
        setupTable()
        setInitialStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
}

private extension MovieSearchViewController {
    
    func setupSearchCallback() {
        searchController.searchPerformedCallback = { [weak self] status in
            guard let self = self else { return }
            
            self.spinner.stopAnimating()
            self.tableView.reloadData()

            switch status {
            case .success:
                self.statusLabel.isHidden = true
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            case .noResult:
                self.statusLabel.text = "No result"
                self.statusLabel.isHidden = false
            case .nothingRequested:
                self.setInitialStatus()
            case .error(let errorMessage):
                self.statusLabel.text = errorMessage
                self.statusLabel.isHidden = false
            }
        }
    }
    
    func setupTable() {
        tableView.allowsSelection = false
        tableView.dataSource = searchController
        tableView.prefetchDataSource = searchController
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func setInitialStatus() {
        statusLabel.isHidden = false
        statusLabel.text = "IMbd"
    }
    
    func search(for movieTitle: String) {
        searchController.search(for: movieTitle)
        spinner.startAnimating()
    }
}

extension MovieSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(for: searchText)
    }
}
