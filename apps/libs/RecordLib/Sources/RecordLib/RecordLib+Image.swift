//
//  RecordLib+Image.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 06.03.2025.
//

import SwiftUICore

// https://www.enekoalonso.com/articles/displaying-images-in-swiftui-views-from-swift-package-resources
extension Image {
    init(packageResource name: String, ofType type: String) {
        guard let path = Bundle.module.path(forResource: name, ofType: type),
              let image = RecordImage(contentsOfFile: path) else {
            self.init(name)
            return
        }
        
        #if canImport(UIKit)
        self.init(uiImage: image)
        #elseif canImport(AppKit)
        self.init(nsImage: image)
        #else
        self.init(name)
        #endif
    }
}
