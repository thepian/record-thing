//
//  WebViewTransparency.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 07.07.23.
//

import WebKit

extension WKWebView {
    
    // https://github.com/ionic-team/capacitor/discussions/4196
    func makeTransparentOnInit() {
        self.isOpaque = false  // part setup for transparency

    }
    
    // https://stackoverflow.com/questions/59925639/how-to-make-transparent-background-wkwebview-in-swift
    func makeTransparentOnViewDidLoad() {
        // part setup for transparency
        self.backgroundColor = .clear
        self.scrollView.backgroundColor = UIColor.clear
    }
}
