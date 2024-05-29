//
//  PlayListViewModel.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/23.
//

import Foundation

struct PlayList {
    let title: String
    let assets: [Asset]
}

struct PlayListViewModel {
    let playlist: [PlayList]
}
