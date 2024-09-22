//
//  ProductType+SwiftUI.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI.Image
extension ProductType {
    var image: Image {
        Image("product/\(rootName)", label: Text(name))
            .renderingMode(.original)
    }
}
