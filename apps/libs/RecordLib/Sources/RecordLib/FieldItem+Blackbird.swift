//
//  FieldItem+Blackbird.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 24.02.2025.
//

import Foundation
import Blackbird

protocol BlackbirdColumnLike {
    associatedtype T where T: Encodable
    var _value: T? { get  }
    var internalNameInSchemaGenerator: Any { get }
}

func getBlackbirdColumnValue<T>(_ value: Any, mirror: Mirror) -> T? where T: Encodable {
//    switch type(of: value) {
//        case BlackbirdColumn<Int>.self:
//        return (value as! BlackbirdColumn<Int>).value
//    }
    if type(of: value) == BlackbirdColumn<Int>.self {
        let column = value as! BlackbirdColumn<Int>
        return column.value as? T
    }
    if type(of: value) == BlackbirdColumn<String>.self {
        let column = value as! BlackbirdColumn<String>
        return column.value as? T
    }
    if type(of: value) == BlackbirdColumn<URL>.self {
        let column = value as! BlackbirdColumn<URL>
        return column.value as? T
    }

    return nil
}

