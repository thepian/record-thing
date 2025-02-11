//
//  SwiftUIView.swift
//  
//
//  Created by Henrik Vendelbo on 25.11.2023.
//

import AVFoundation
import CoreImage

extension AVMetadataObject {
    func isJunkMetadata() -> Bool {
        if type == .salientObject {
            let salient = self as! AVMetadataSalientObject
            if bounds.width == 1.0 && bounds.height == 1.0 && bounds.minX == 0.0 && bounds.minY == 0.0 {
                return true
            }
            if salient.objectID == 0 {
                return true
            }
        }
        return false
    }
}

extension VisionService: AVCaptureMetadataOutputObjectsDelegate {
    
    // Called within Session Queue
    func setupMetaDetectionSession() {
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
// TODO            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//            metadataOutput.metadataObjectTypes = [.qr, .ean13, .code128] // Blows up in simulator
            metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes.filter({
                if #available(iOS 17.0, *) {
                    if $0 == .humanFullBody {
                        return false
                    }
                }
                switch $0 {
                case .catBody, .dogBody, .humanBody: return false
                default: return true
                }
            }) // Use all metadata object types by default.
            
            /*
             
             let formatDimensions = CMVideoFormatDescriptionGetDimensions(self.videoDeviceInput.device.activeFormat.formatDescription)
             self.rectOfInterestWidth = Double(formatDimensions.height) / Double(formatDimensions.width)
             self.rectOfInterestHeight = 1.0
             let xCoordinate = (1.0 - self.rectOfInterestWidth) / 2.0
             let yCoordinate = (1.0 - self.rectOfInterestHeight) / 2.0
             let initialRectOfInterest = CGRect(x: xCoordinate, y: yCoordinate, width: self.rectOfInterestWidth, height: self.rectOfInterestHeight)
             metadataOutput.rectOfInterest = initialRectOfInterest

             DispatchQueue.main.async {
                 let initialRegionOfInterest = self.previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: initialRectOfInterest)
                 self.previewView.setRegionOfInterestWithProposedRegionOfInterest(initialRegionOfInterest)
             
             */
        }
    }
    
    func interpretPerson(_ metadataObject: AVMetadataObject) -> ObservedPerson? {
        if let face = metadataObject as? AVMetadataFaceObject {
            var person = ObservedPerson(hasRollAngle: face.hasRollAngle, rollAngle: face.rollAngle, hasYawAngle: face.hasYawAngle, yawAngle: face.yawAngle)
            person.faceID = face.faceID
            person.isNew = !observedPerson.contains { observed in
                observed.faceID == person.faceID
//                observed.descriptor == person.descriptor
            }
            return person
        }
        return nil
    }
    
    func appendPerson(_ person: ObservedPerson) {
        observedPerson.append(person)
        print("Appended known person:", person.debugDescription)
    }

    
    func interpretMachineReadableCode(_ machineReadableCode: AVMetadataMachineReadableCodeObject) -> ObservedBarcode? {
        var barcode = ObservedBarcode(payload: "")
        barcode.descriptor = machineReadableCode.descriptor
        if #available(iOS 15.4, *) {
            switch machineReadableCode.type {
            case .qr, .microQR:
                if let qr = machineReadableCode.descriptor as? CIQRCodeDescriptor {
                    barcode.payload = machineReadableCode.stringValue ?? ""
                    barcode.data = qr.errorCorrectedPayload
                    barcode.symbolVersion = qr.symbolVersion
                }
            case .pdf417, .microPDF417:
                if let pdf = machineReadableCode.descriptor as? CIPDF417CodeDescriptor {
                    barcode.data = pdf.errorCorrectedPayload
                    barcode.payload = pdf.errorCorrectedPayload.description
                }
            case .ean8, .ean13:
                break;
            case .code39, .code93, .code128, .codabar, .dataMatrix:
                break;
            
            default:
                return nil  // case .salientObject, .face, .humanBody, .catBody, .dogBody:
            }
        } else {
            // Fallback on earlier versions
            switch machineReadableCode.type {
            case .qr:
                if let qr = machineReadableCode.descriptor as? CIQRCodeDescriptor {
                    barcode.payload = qr.errorCorrectedPayload.description
                    barcode.data = qr.errorCorrectedPayload
                    barcode.symbolVersion = qr.symbolVersion
                }
            case .pdf417:
                if let pdf = machineReadableCode.descriptor as? CIPDF417CodeDescriptor {
                    barcode.data = pdf.errorCorrectedPayload
                    barcode.payload = pdf.errorCorrectedPayload.description
                }
            case .ean8, .ean13:
                break;
            case .code39, .code93, .code128, .dataMatrix:
                break;

            default:
                return nil  // case .salientObject, .face, .humanBody, .catBody, .dogBody:
            }
        }
        
//        machineReadableCode.corners [point]
        
        // TODO if not already known/observed/tracked
        barcode.isNew = !observedBarcodes.contains { observed in
            observed == barcode
        }
        
        /*
         
         <AVMetadataFaceObject: 0x2817a2240, faceID=1, bounds={0.2,0.1 0.0x0.1}, rollAngle=270.0, yawAngle=45.0, pitchAngle=-1.0, time=129706145166833>
         <AVMetadataFaceObject: 0x2817c8640, faceID=1, bounds={0.2,0.0 0.0x0.1}, rollAngle=270.0, yawAngle=45.0, pitchAngle=-1.0, time=129706178514000>
         <AVMetadataFaceObject: 0x2817a0b80, faceID=1, bounds={0.2,0.0 0.0x0.1}, rollAngle=270.0, yawAngle=45.0, pitchAngle=-1.0, time=129706211850708>
         <AVMetadataFaceObject: 0x2817c8180, faceID=1, bounds={0.2,0.0 0.0x0.1}, rollAngle=270.0, yawAngle=45.0, pitchAngle=-1.0, time=129706245197875>
         */
        
        return barcode
    }
    
    func appendMachineReadableCode(_ foundCode: ObservedBarcode) {
        observedBarcodes.append(foundCode)
        print("Appended barcode:", foundCode.debugDescription)
    }
            

    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    // humanBody, dogBody, catBody, salientObject, face, QRCode, MicroQR, EAN, UPC-E, Codabar
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Drop new notifications if old ones are still processing using `wait()`, to avoid queueing up stale data.
        if metadataObjectsSemaphore.wait(timeout: .now()) == .success {
            DispatchQueue.main.async { [self] in
//                self.removeMetadataObjectOverlayLayers()
                
//                var metadataObjectOverlayLayers = [MetadataObjectLayer]()
                for metadataObject in metadataObjects {
                    if !metadataObject.isJunkMetadata() {
                        if let person = interpretPerson(metadataObject) {
                            if person.isNew {
                                appendPerson(person)
                            }
                        } else if let machineReadableCode = metadataObject as? AVMetadataMachineReadableCodeObject {
                            if let foundCode = interpretMachineReadableCode(machineReadableCode) {
                                if foundCode.isNew {
                                    appendMachineReadableCode(foundCode)
                                    // TODO register new domain trying to install it
                                    let process = InteractionProcess(installURL: foundCode.payload)
                                    model?.startProcess(process)
                                }
                            }
                        }

                        else {
                            print(String(describing: metadataObject))
                        }
                    }
                }

//                for metadataObject in metadataObjects {
//                    let metadataObjectOverlayLayer = self.createMetadataObjectOverlayWithMetadataObject(metadataObject)
//                    metadataObjectOverlayLayers.append(metadataObjectOverlayLayer)
//                }
                
//                self.addMetadataObjectOverlayLayersToVideoPreviewView(metadataObjectOverlayLayers)
                
                self.metadataObjectsSemaphore.signal()
            }
        }
    }
}
