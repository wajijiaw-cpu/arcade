//
//  ViewController.swift
//  像素放映厅 · iOS 壳
//  全屏 WKWebView 打开大厅页面，仅此而已。
//

import UIKit
import WebKit

final class ViewController: UIViewController {

    private var webView: WKWebView!

    // 系统触感：页面里的虚拟按键按下时经 JS 桥发来消息，这里触发真震感
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticHandler = HapticMessageHandler()

    // 隐藏状态栏，全屏显示
    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let configuration = WKWebViewConfiguration()
        // 注册触感桥：window.webkit.messageHandlers.arcadeHaptic
        hapticHandler.owner = self
        configuration.userContentController.add(hapticHandler, name: "arcadeHaptic")
        // 视频/动画在页面内直接播放，不跳全屏播放器
        configuration.allowsInlineMediaPlayback = true
        // 游戏声音不需要用户先点一下才允许播放
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // JavaScript 默认开启（大厅是网页应用，必须开）
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.webView = webView

        impactLight.prepare()
        loadHall()
    }

    /// 页面请求一次触感反馈（body 为 "medium" 时更重，其余一律轻触）
    func performHaptic(style: String?) {
        if style == "medium" {
            impactMedium.impactOccurred()
            impactMedium.prepare()
        } else {
            impactLight.impactOccurred()
            impactLight.prepare()
        }
    }

    private func loadHall() {
        webView.load(URLRequest(url: HallConfig.hallURL))
    }
}

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        handleLoadError(error)
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        handleLoadError(error)
    }

    private func handleLoadError(_ error: Error) {
        // 被新一次加载取消的回调不算失败，不弹窗
        if (error as NSError).code == NSURLErrorCancelled { return }
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "连不上大厅",
                                      message: "请确认手机和 NAS 在同一个局域网里，且大厅正在运行。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.loadHall()
        })
        present(alert, animated: true)
    }
}

/// JS 桥的转发小对象：弱引用控制器，避免和 WebView 配置互相强引用
final class HapticMessageHandler: NSObject, WKScriptMessageHandler {

    weak var owner: ViewController?

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "arcadeHaptic" else { return }
        let style = message.body as? String
        DispatchQueue.main.async { [weak self] in
            self?.owner?.performHaptic(style: style)
        }
    }
}
