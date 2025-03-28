//
//  RecordButton.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 11.07.23.
//

import SwiftUI

public struct RecordButton: View {
    @Environment(\.cameraViewModel) var model
    @State private var timer: Timer?
    @State var isLongPressing = false
    
    var snap: () -> Void
    var start: () -> Void
    var end: () -> Void
 
    public var body: some View {
        Button(action: {
            if self.isLongPressing {
                //this tap was caused by the end of a longpress gesture, so stop our fastforwarding
                self.isLongPressing.toggle()
                self.timer?.invalidate()
                end()
                
            } else {
                snap()
            }
            
        }) {
            Circle()
                .stroke(.white, lineWidth: 4)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 50, height: 50)
                )
        }
          .buttonStyle(.plain)
          .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in
                    start()
                    self.isLongPressing = true
                    //or fastforward has started to start the timer
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                        })
                    }
          )        
    }
}

#if DEBUG
struct RecordButton_Previews: PreviewProvider {
    static var previews: some View {
        let model = CameraViewModel(status: .authorized)
        @State var snaps: Int = 0
        @State var recordings: Int = 0
        @State var recording = false

        ZStack {
            Color.red
            VStack {
                Spacer()
                HStack {
                    RecordButton(
                        snap: {
                            snaps += 1
                            print("snap")
                        },
                        start: {
                            recording = true
                            print("start")
                        },
                        end: {
                            print("end")
                            recording = false
                            recordings += 1
                        })
                    .environment(\.cameraViewModel, model)
                }
                Spacer()
                if recording {
                    Text("[recording]")
                }
                Text("\(snaps) snaps")
                Text("\(recordings) recordings")

            }
        }
    }
}
#endif
