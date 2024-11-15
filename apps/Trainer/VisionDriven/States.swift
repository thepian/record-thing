//
//  File.swift
//  
//
//  Created by Henrik Vendelbo on 14.10.2023.
//

import Foundation
import AVFoundation
import CoreImage

public enum WebViewZoomState: String {
    case TwoThirds, FullScreen, Hidden
}

struct ObservedPerson {
    var faceID: Int = 0
    var hasRollAngle: Bool = false
    var rollAngle: CGFloat = 0
    var hasYawAngle: Bool = false
    var yawAngle: CGFloat = 0

    var isNew: Bool = false
    
    var debugDescription: String {
        get {
            return  """
                    faceID \(faceID)
                    roll   \(rollAngle) \(hasRollAngle)
                    yaw    \(yawAngle) \(hasYawAngle)
                    """
        }
    }
}

struct ObservedBarcode {
    var data: Data?
    var payload: String
    var symbolVersion: Int = 0
    var descriptor: CIBarcodeDescriptor?
    var isNew: Bool = false
    
    static func == (_ a: ObservedBarcode, _ b: ObservedBarcode) -> Bool {
        if a.payload != "" && a.payload == b.payload {
            return true
        }
        return a.descriptor == b.descriptor
    }
    
    var debugDescription: String {
        get {
            return  """
                    payload \(payload.debugDescription)
                    descr   \(descriptor.debugDescription)
                    data    \(data?.description ?? "<nil>")
                    """
        }
    }
}

/*
 Observed Document or Object in the environment. Information gathered from what was seen and tentatively matched with persisted information.
 */
public struct ObservedObject {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
//    var color: UIColor
//    var style: TrackedObservationStyle
//    var classification: DocumentClassification = .NotDocument
//    var rectObservation: VNRectangleObservation?
    
    var cornerPoints: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    var boundingBox: CGRect {
        let topLeftRect = CGRect(origin: topLeft, size: .zero)
        let topRightRect = CGRect(origin: topRight, size: .zero)
        let bottomLeftRect = CGRect(origin: bottomLeft, size: .zero)
        let bottomRightRect = CGRect(origin: bottomRight, size: .zero)

        return topLeftRect.union(topRightRect).union(bottomLeftRect).union(bottomRightRect)
    }
    
    var debugDescription: String {
        get {
            return  """
                    TL \(topLeft.debugDescription)
                    TR \(topRight.debugDescription)
                    BL \(bottomLeft.debugDescription)
                    BR \(bottomRight.debugDescription)
                    """
//                    confidence: \(rectObservation?.confidence ?? 0)
//                    class \(classification.rawValue)
//                    """
        }
    }
    
    init(_ from: AVMetadataObject) {
//        from.type
//        from.time
//        from.duration
//        from.bounds
//        from.observationInfo
        topLeft = from.bounds.topLeft
        topRight = from.bounds.topRight
        bottomLeft = from.bounds.bottomLeft
        bottomRight = from.bounds.bottomRight
    }
    
    // Switch to mutable object?
    
//    func setTextClassification(_ cls: TextClassification) {
//        classification = cls.documentClassification
////        print("classification: \(cls.description)")
//
//    }
    
    /*
    init(observation: VNDetectedObjectObservation, color: UIColor, style: TrackedObservationStyle = .solid) {
        self.init(cgRect: observation.boundingBox, color: color, style: style)
    }
    
    init(observation: VNRectangleObservation, color: UIColor, style: TrackedObservationStyle = .solid) {
        topLeft = observation.topLeft
        topRight = observation.topRight
        bottomLeft = observation.bottomLeft
        bottomRight = observation.bottomRight
        self.color = color
        self.style = style
        rectObservation = observation
    }

    init(cgRect: CGRect, color: UIColor, style: TrackedObservationStyle = .solid) {
        topLeft = CGPoint(x: cgRect.minX, y: cgRect.maxY)
        topRight = CGPoint(x: cgRect.maxX, y: cgRect.maxY)
        bottomLeft = CGPoint(x: cgRect.minX, y: cgRect.minY)
        bottomRight = CGPoint(x: cgRect.maxX, y: cgRect.minY)
        self.color = color
        self.style = style
    }
    */
}

