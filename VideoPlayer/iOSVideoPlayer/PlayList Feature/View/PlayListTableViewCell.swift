//
//  PlayListTableViewCell.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import UIKit

class PlayListTableViewCell: UITableViewCell {
    
    static let ReuseIdentifier = "PlayListTableViewCell"
    
    
    // MARK: - Properties
    
    var viewModel: PlayListTableViewCellViewModel? {
        didSet {
            textLabel?.text = viewModel?.title
        }
    }
    
    
    // MARK: - Life Cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
}
