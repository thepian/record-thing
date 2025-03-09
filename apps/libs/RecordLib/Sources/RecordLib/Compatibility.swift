//
//  Compatibility.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 24.02.2025.
//

import Foundation

extension URL {
    static func platformCompatible(string: String) -> URL? {
        #if os(macOS)
        if string.starts(with: "file://") {
            return URL(filePath: String(string.dropFirst(7)))
        }
        #endif
        return URL(string: string)
    }
    
    var platformPath: String {
        #if os(macOS)
        return self.path()
        #else
        return self.path
        #endif
    }
    
    init(platformFilePath path: String) {
        #if os(macOS)
        self.init(filePath: path)
        #else
        self.init(fileURLWithPath: path)
        #endif
    }
}

