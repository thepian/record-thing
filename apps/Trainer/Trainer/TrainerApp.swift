//
//  TrainerApp.swift
//  Trainer
//
//  Created by Henrik Vendelbo on 17.06.2024.
//

import SwiftUI

@main
struct TrainerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TrainerDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
