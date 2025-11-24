//
//  AppIdentityView.swift
//  ThepiaApp
//
//  Created by Henrik Vendelbo on 20.11.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import RecordLib
import SwiftUI

struct AppIdentityView: View {
    @EnvironmentObject private var model: Model
    
    var body: some View {
        GeometryReader { geometry in
            model.identityImage
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: geometry.size.width, height: geometry.size.height)
              .clipped()  // This prevents the image from overflowing
        }
        .ignoresSafeArea()
    }
}
