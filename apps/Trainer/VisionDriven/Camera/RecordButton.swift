//
//  RecordButton.swift
//  Treasure
//
//  Created by Henrik Vendelbo on 11.07.23.
//

import SwiftUI

public protocol RecordingTriggers {
    func snap() -> Void
    func start() -> Void
    func end() -> Void
}

public struct RecordButton: View {
    @EnvironmentObject var model: VDViewModel
    @State private var timer: Timer?
    @State public var isLongPressing = false
    
    public var triggers: RecordingTriggers
 
    public init(triggers: RecordingTriggers) {
        self.triggers = triggers
    }

    public var body: some View {
        Button(action: {
            if self.isLongPressing {
                //this tap was caused by the end of a longpress gesture, so stop our fastforwarding
                self.isLongPressing.toggle()
                self.timer?.invalidate()
                triggers.end()
                
            } else {
                triggers.snap()
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
          .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in
                    triggers.start()
                    self.isLongPressing = true
                    //or fastforward has started to start the timer
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                        })
                    }
          )        
    }
}

struct RecordButton_Previews: PreviewProvider {
    class RT: NSObject, ObservableObject, RecordingTriggers {
        var snaps: Int = 0
        var recordings: Int = 0
        var recording = false

        func snap() {
            snaps += 1
            print("snap")
        }
        
        func start() {
            recording = true
            print("start")
        }
        
        func end() {
            print("end")
            recording = false
            recordings += 1
        }
    }

    static var previews: some View {
        let model = VDViewModel()
        
        @StateObject var triggers = RT()
        
        ZStack {
            Color.red
            VStack {
                Spacer()
                HStack {
                    RecordButton(triggers: triggers)
                    .environmentObject(model)
                }
                Spacer()
                if triggers.recording {
                    Text("[recording]")
                }
                Text("\(triggers.snaps) snaps")
                Text("\(triggers.recordings) recordings")

            }
        }
    }
}
