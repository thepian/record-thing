//
//  DocumentType+SwiftUI.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 23.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI.Image
extension DocumentType {
    var image: Image {
        Image("document/\(rootName)", label: Text(name))
            .renderingMode(.original)
    }
}
