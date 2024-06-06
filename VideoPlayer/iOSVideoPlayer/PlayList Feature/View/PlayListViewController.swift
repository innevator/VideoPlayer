//
//  PlayListViewController.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import UIKit

class PlayListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let router: Router
    private let service: AssetService
    private var viewModel = PlayListViewModel(playlist: []) {
        didSet { self.tableView.reloadData() }
    }
    let tableView = UITableView()
    
    
    // MARK: - Initializer
    
    init(router: Router, service: AssetService) {
        self.router = router
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getAssets()
    }
    
    
    // MARK: - UI setup
    
    private func setupUI() {
        title = String(.playListTitle)
        view.backgroundColor = .systemBackground
        setupPlayListTableView()
    }
    
    private func setupPlayListTableView() {
        let tableView = self.tableView
        tableView.register(PlayListTableViewCell.self, forCellReuseIdentifier: PlayListTableViewCell.ReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
    }
    
    
    // MARK: - API request
    
    private func getAssets() {
        service.getAssets { result in
            switch result {
            case .success(let assets):
                let playlist = assets.map { PlayList(title: $0.name, assets: [$0])}
                self.viewModel = PlayListViewModel(playlist: playlist)
               
            case .failure(_):
                self.router.go(.alert(title: String(.getAssetsFailedAlertTitle), 
                                      message: nil,
                                      actions: [.cancel(String(.getAssetsFailedAlertActionTitle))]))
            }
        }
    }
}


// MARK: - UITableViewDataSource

extension PlayListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlayListTableViewCell.ReuseIdentifier) as? PlayListTableViewCell else {
            return UITableViewCell()
        }
        
        let playlist = viewModel.playlist[indexPath.row]
        cell.viewModel = PlayListTableViewCellViewModel(playlist: playlist)
        
        return cell
    }
}


// MARK: - UITableViewDelegate

extension PlayListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let assets = viewModel.playlist[indexPath.row].assets
        router.go(.playVideo(assets: assets))
    }
}
