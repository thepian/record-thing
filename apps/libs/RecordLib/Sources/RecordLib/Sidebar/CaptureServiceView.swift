//
//  CaptureServiceView.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 11.04.2025.
//

import SwiftUI

public struct CaptureServiceInfo: View {
    @ObservedObject var captureService: CaptureService
    
    public init(captureService: CaptureService) {
        self.captureService = captureService
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Streaming Control
            HStack {
                Label("Stream", systemImage: "video")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { !captureService.isPaused },
                    set: { newValue in
                        if newValue {
                            captureService.resumeStream()
                        } else {
                            captureService.pauseStream()
                        }
                    }
                ))
                .labelsHidden()
            }
            
            #if os(iOS)
            // Orientation Info
            HStack {
                Label("Orientation", systemImage: "rotate.3d")
                Spacer()
                Text(String(describing: captureService.currentOrientation))
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            #endif
        }
        .padding(.vertical, 4)
    }
}


