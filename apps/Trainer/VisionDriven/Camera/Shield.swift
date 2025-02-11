//
//  Shield.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 01.07.23.
//

import SwiftUI

func RoundRectHoleShapeMask(in rect: CGRect) -> Path {
    var shape = Rectangle().path(in: rect)
    shape.addPath(Circle().path(in: rect))
    return shape
}



public struct Shield: View {
    @State private var width: CGFloat = 180

    let rect = CGRect(x: 0, y: 0, width: 320, height: 320)
    let cornerSize: CGSize = CGSize(width: 30, height: 30)
    let insets = EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0)

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            Color.black
                .frame(idealWidth: self.width, maxWidth: geometry.size.width, idealHeight: geometry.size.height)
                .opacity(0.4)
                .mask(
                    Color.black.overlay(
                        RoundedRectangle(cornerSize: cornerSize)
                            .position(CGPoint(x: rect.width/2, y: 10))
                            .frame(width: rect.width, height: rect.height)
                            .blendMode(.destinationOut)
                        )
                    .compositingGroup()
                )
                .ignoresSafeArea()
        }
        
    }
}

struct Shield_Previews: PreviewProvider {
    static var previews: some View {
        Shield()
    }
}
