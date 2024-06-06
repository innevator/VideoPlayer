//
//  PlayListViewController+Helpers.swift
//  iOSVideoPlayerTests
//
//  Created by 洪宗鴻 on 2024/6/6.
//

import UIKit
@testable import iOSVideoPlayer

extension PlayListViewController {
    
    func numberOfRenderedPlayListViews() -> Int {
        tableView.numberOfRows(inSection: section)
    }
    
    func simulatePlayListViewVisible(at row: Int = 0) -> PlayListTableViewCell? {
        return playListView(at: row) as? PlayListTableViewCell
    }
    
    func simulateTapPlayVideo(at row: Int = 0) {
        tableView(tableView, didSelectRowAt: IndexPath(row: row, section: section))
    }
    
    private func playListView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        return ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: section))
    }
    
    private var section: Int {
        return 0
    }
}
