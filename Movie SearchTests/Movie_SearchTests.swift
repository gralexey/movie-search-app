//
//  Movie_SearchTests.swift
//  Movie SearchTests
//
//  Created by Alexey Grabik on 15/04/2020.
//

import XCTest
@testable import Movie_Search

class Movie_SearchTests: XCTestCase {
    
    var searchController: SearchController?

    override func setUp() {
        searchController = SearchController(networkService: MockNetworkAPI())
    }

    override func tearDown() {
        searchController = nil
    }

    func testSearch() {
        let searchTestExpectation = XCTestExpectation(description: "search for some movies")
        searchController?.searchPerformedCallback = { status in
            switch status {
            case .success:
                searchTestExpectation.fulfill()
            default:
                XCTFail()
            }
        }
        searchController?.search(for: "some")
        wait(for: [searchTestExpectation], timeout: 10.0)
    }
    
    func testEmptySearch() {
        let searchTestExpectation = XCTestExpectation(description: "search for no movies")
        searchController?.searchPerformedCallback = { status in
            switch status {
            case .nothingRequested:
                searchTestExpectation.fulfill()
            default:
                XCTFail()
            }
        }
        searchController?.search(for: "")
        wait(for: [searchTestExpectation], timeout: 10.0)
    }
}
