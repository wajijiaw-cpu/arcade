//
//  AppDelegate.swift
//  像素放映厅 · iOS 壳
//
//  大厅地址只写在下面 HallConfig 这一处；NAS 的 IP 变了，改这一行重新构建即可。
//

import UIKit

enum HallConfig {
    /// 大厅地址（自家局域网）
    static let hallURL = URL(string: "http://192.168.0.78:18888/")!
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 玩游戏时屏幕不自动锁定、变暗
        UIApplication.shared.isIdleTimerDisabled = true

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
