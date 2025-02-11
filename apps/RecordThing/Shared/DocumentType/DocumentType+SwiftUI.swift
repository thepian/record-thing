//
//  DocumentType+SwiftUI.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI.Image
extension DocumentType {
    var image: Image {
        Image("product/Room", label: Text(name))
            .renderingMode(.original)
//        Image("document/\(rootName)", label: Text(name))
//            .renderingMode(.original)
    }
}
