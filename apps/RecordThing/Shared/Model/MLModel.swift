//
//  MLModel.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 14.09.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Blackbird

// Required to use with the @StateObject wrapper
extension Blackbird.Database: ObservableObject { }

struct MLModel {
    var name: String
}
