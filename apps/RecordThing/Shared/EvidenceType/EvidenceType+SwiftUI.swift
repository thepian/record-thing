//
//  EvidenceType+SwiftUI.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 21.09.2024.
//  Copyright © 2025 Thepia. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI.Image
extension EvidenceType {
    var image: Image {
        Image("product/Room", label: Text(name))
            .renderingMode(.original)

//        Image("product/\(rootName)", label: Text(name))
//            .renderingMode(.original)
    }
}
