//
//  SubtitleSelectionViewController.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/22.
//

import AVFoundation
import UIKit

protocol SubtitleSelectionDelegate: AnyObject {
    func onSubtitleTrackSelected(subtitleTrack: AVMediaSelectionOption?)
    func onDismissed()
}

class SubtitleSelectionViewController: UIViewController {
    private static let cellIdentifier = "SubtitleCell"
    
    private let popOverView = UIView().configure {
        $0.backgroundColor = VideoPlayerColor(palette: .black).uiColor
        $0.roundCorners(cornerRadius: CGFloat.space40 / 2)
    }
    
    private let tableView = UITableView().configure { tableView in
        tableView.register(SelectionCellView.self, forCellReuseIdentifier: cellIdentifier)
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
    }
    
    private let grabberView = UIView().configure {
        $0.backgroundColor = VideoPlayerColor(palette: .white).uiColor.withAlphaComponent(0.5)
        $0.layer.cornerRadius = CGFloat.space6 / 2
    }
    
    private let header = UILabel().configure {
        $0.textColor = VideoPlayerColor(palette: .pearlWhite).uiColor
        $0.text = "Subtitle"
        $0.font = FontUtility.helveticaNeueMedium(ofSize: 16)
    }
    
    weak var delegate: SubtitleSelectionDelegate?
    private let viewModel: SubtitleSelectionViewModel
    
    init(viewModel: SubtitleSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        modalPresentationStyle = .popover
    }
    
    private func setupView() {
        view.addSubview(popOverView)
        popOverView.snp.makeConstraints { make in
            make.width.equalTo(375)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-CGFloat.space40)
            make.top.greaterThanOrEqualToSuperview().offset(CGFloat.space40)
        }
        
        setupPopOverView()
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        let overlayTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissView))
        overlayTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(overlayTapGesture)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissView))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        popOverView.addGestureRecognizer(swipeDown)
    }
    
    private func setupPopOverView() {
        popOverView.addSubview(grabberView)
        popOverView.addSubview(header)
        popOverView.addSubview(tableView)
        
        grabberView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(CGFloat.space8)
            make.width.equalTo(44)
            make.height.equalTo(CGFloat.space6)
        }
        
        header.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(grabberView.snp.bottom).offset(CGFloat.space40 / 2)
        }
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(CGFloat.space16)
            make.leading.equalToSuperview().offset(CGFloat.space24)
            make.trailing.equalToSuperview().offset(-CGFloat.space24)
            make.bottom.equalToSuperview().offset(-CGFloat.space8)
            make.height.equalTo(CGFloat.space128)
        }
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
        delegate?.onDismissed()
    }
}

extension SubtitleSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.subtitleOptionsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleSelectionViewController.cellIdentifier, for: indexPath) as! SelectionCellView
        let subtitleLanguage = viewModel.subtitleOption(indexPath.row)
        let isSelected = indexPath.row == viewModel.selectedItemIndex
        cell.configureCell(title: subtitleLanguage, isSelected: isSelected)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedItemIndex = indexPath.row
        tableView.reloadData()
        delegate?.onSubtitleTrackSelected(subtitleTrack: viewModel.subtitleTrack)
        dismissView()
    }
    
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return CGFloat.space38
    }
}
