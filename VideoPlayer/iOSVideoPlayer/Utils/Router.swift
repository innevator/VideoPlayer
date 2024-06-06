//
//  Router.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/16.
//

import UIKit
import VideoPlayer

class Router {
    
    enum RoutableView {
        case playVideo(assets: [Asset])
        case alert(title: String?, message: String?, actions: [UIAlertAction])
    }
    
    private let navigationVC: UINavigationController = UINavigationController(rootViewController: UIViewController())
    
    func root() -> UIViewController {
        let playListVC = PlayListViewController(router: self, service: AssetService())
        navigationVC.viewControllers = [playListVC]
        return navigationVC
    }
    
    func go(_ routable: RoutableView) {
        switch routable {
        case .playVideo(let assets):
            let playVideoVC = PlayVideoViewController(router: self, assets: assets)
            navigationVC.pushViewController(playVideoVC, animated: true)
            
        case .alert(let title, let message, let actions):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            actions.forEach { alert.addAction($0) }
            navigationVC.topViewController?.present(alert, animated: true)
        }
    }
    
    func backToPrevious(animated: Bool = true) {
        navigationVC.popViewController(animated: animated)
    }
}
