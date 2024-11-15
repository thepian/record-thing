//
//  CustomARViewRepresentable.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 02.07.23.
//

import SwiftUI

struct CustomARViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomARView {
        return CustomARView()
    }
    
    func updateUIView(_ uiView: CustomARView, context: Context) { }
}

struct CustomARViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        CustomARViewRepresentable()
            .environmentObject(ViewModel())
            .ignoresSafeArea()
    }
}

