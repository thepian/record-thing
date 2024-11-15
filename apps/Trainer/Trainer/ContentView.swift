//
//  ContentView.swift
//  Trainer
//
//  Created by Henrik Vendelbo on 17.06.2024.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: TrainerDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(TrainerDocument()))
}
