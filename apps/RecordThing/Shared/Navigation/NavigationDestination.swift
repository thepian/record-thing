//
//  NavigationDestination.swift
//  RecordThing
//
//  Created by Henrik Vendelbo on 28.03.2025.
//  Copyright © 2025 Apple. All rights reserved.
//

import RecordLib

typealias UUID = String

// Navigation Path Segments
enum NavigationDestination: Hashable {
    // Record Tab
    case record(evidenceId: UUID?)
    
    // Internal Tab Paths
//    case internalData
//    case internalThings
//    case internalTypes
//    case internalFeed
//    case internalFavorites
//    case internalDataBrowse(title: String, path: String)
    
    // Assets Tab Paths
    case assets
    case assetsGroup(groupId: String)
    case assetsDetail(assetId: UUID)
    case assetsThingDetail(thingId: UUID)
    case assetsEvidenceList(thingId: UUID)
    case assetsEvidenceDetail(thingId: UUID, evidenceId: UUID)
    
    // Actions Tab Paths
    case actions
    case actionsAccount
    case actionsSettings
    case actionsHelp
    
    // Helper computed property for tab identification
    var tab: BrowseNavigationTab {
        switch self {
        case .record:
            return .record
//        case .internalData, .internalThings, .internalTypes, .internalFeed, .internalFavorites, .internalDataBrowse:
//            return .internalData
        case .assets, .assetsGroup, .assetsDetail, .assetsThingDetail, .assetsEvidenceList, .assetsEvidenceDetail:
            return .assets
        case .actions, .actionsAccount, .actionsSettings, .actionsHelp:
            return .actions
        }
    }
}
