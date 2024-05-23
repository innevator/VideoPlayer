//
//  AppDelegate.swift
//  iOSVideoPlayer
//
//  Created by 洪宗鴻 on 2024/5/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow()
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}

