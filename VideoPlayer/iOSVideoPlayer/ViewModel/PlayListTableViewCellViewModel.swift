//
//  PlayListTableViewCellViewModel.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/17.
//

import Foundation

struct PlayListTableViewCellViewModel {
    private let playlist: PlayList
    
    var title: String { return playlist.title }
    
    init(playlist: PlayList) {
        self.playlist = playlist
    }
}
