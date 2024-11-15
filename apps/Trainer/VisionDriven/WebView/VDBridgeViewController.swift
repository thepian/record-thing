//
//  File.swift
//  
//
//  Created by Henrik Vendelbo on 15.10.2023.
//

import UIKit
import Capacitor

extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}

public class VDBridgeViewController: CAPBridgeViewController {
    weak public var model: VDViewModel?
    weak public var visionService: VisionService?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        webView!.makeTransparentOnViewDidLoad()
    }
    
    // Forward secrecy certs required: https://stackoverflow.com/questions/71678158/didfailprovisionalloadforframe-for-certain-url-but-works-fine-in-safari

    public override func webView(with frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        // Attempting to fix DiskCookieStorage changing policy from 2 to 0
        let wkDataStore = WKWebsiteDataStore.nonPersistent()
        wkDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
            // completion
        }
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            wkDataStore.httpCookieStore.setCookie(cookie)
        }
        configuration.websiteDataStore = wkDataStore
        
        //        configuration.websiteDataStore.httpCookieStore
        //        configuration.setcookiePolicy
        let frameWithInsetErrorFix = CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1)
        let webView = WKWebView(frame: frameWithInsetErrorFix, configuration: configuration) 
        webView.makeTransparentOnInit()
        if #available(macOS 13.3, iOS 16.4, tvOS 16.4, *) {
            webView.isInspectable = true
        }
        let upSwipeGesture = UISwipeGestureRecognizer(target: webView, action: #selector(viewEdgeSwiped))
        upSwipeGesture.direction = .up
        //        let downSwipeGesture = UISwipeGestureRecognizer()
        
//        webView.addGestureRecognizer(upSwipeGesture) - crashes, not yet working state
        
        model?.$processURLtoLoad.sink { urlString in
            if let urlStr = urlString, let url = URL(string: urlStr) {
                webView.load(URLRequest(url: url))
            }
        }
        return webView
    }
    
    @objc func viewEdgeSwiped(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.state == .recognized {
            print("Swiped")
        }
    }
}
