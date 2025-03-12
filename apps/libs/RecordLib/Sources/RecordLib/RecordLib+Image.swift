//
//  RecordLib+Image.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 06.03.2025.
//

import SwiftUICore
import UIKit

// https://www.enekoalonso.com/articles/displaying-images-in-swiftui-views-from-swift-package-resources
extension Image {
    init(packageResource name: String, ofType type: String) {
        #if canImport(UIKit)
        guard let path = Bundle.module.path(forResource: name, ofType: type),
              let image = UIImage(contentsOfFile: path) else {
            self.init(name)
            return
        }
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        guard let path = Bundle.module.path(forResource: name, ofType: type),
              let image = NSImage(contentsOfFile: path) else {
            self.init(name)
            return
        }
        self.init(nsImage: image)
        #else
        self.init(name)
        #endif
    }
}

