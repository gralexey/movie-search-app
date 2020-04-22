//
//  MovieSearchViewController.swift
//  Movie Search
//
//  Created by Alexey Grabik on 15/04/2020.
//

import UIKit

class MovieSearchViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var spinner: UIActivityIndicatorView!
    private let searchController = SearchController()

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
    
    func tryScrollToTop() {
        if searchController.tableView(tableView, numberOfRowsInSection: 0) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func setupSearchCallback() {
        searchController.searchPerformedCallback = { [weak self] status in
            guard let self = self else { return }
            
            self.spinner.stopAnimating()
            self.tableView.reloadData()

            switch status {
            case .success:
                self.statusLabel.isHidden = true
                self.tryScrollToTop()
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
        statusLabel.text = "IMdb"
    }
    
    func search(forMovie movieTitle: String) {
        searchController.search(forMovie: movieTitle)
        spinner.startAnimating()
    }
}

extension MovieSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(forMovie: searchText)
    }
}
