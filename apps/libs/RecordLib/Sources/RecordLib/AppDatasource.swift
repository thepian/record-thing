//
//  AppDatasource.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 30.03.2025.
//

import SwiftUICore
import Blackbird

// MARK: - AppDatasourceAPI Protocol
public protocol AppDatasourceAPI: ObservableObject {
    var db: Blackbird.Database? { get }
    func reloadDatabase()
    func resetDatabase()
    func updateDatabase() async
}

// MARK: - Database Environment Key
private struct DatabaseKey: EnvironmentKey {
    static let defaultValue: Blackbird.Database? = nil
}

private struct DatasourceKey: EnvironmentKey {
    static let defaultValue: (any AppDatasourceAPI)? = nil
}

extension EnvironmentValues {
    public var database: Blackbird.Database? {
        get { self[DatabaseKey.self] }
        set { self[DatabaseKey.self] = newValue }
    }
    
    public var appDatasource: (any AppDatasourceAPI)? {
        get { self[DatasourceKey.self] }
        set { self[DatasourceKey.self] = newValue }
    }
}

