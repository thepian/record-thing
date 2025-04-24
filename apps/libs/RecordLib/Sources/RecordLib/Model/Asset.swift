//
//  Asset.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 25.04.2025.
//

import Foundation
import SwiftUICore
import os

/// Used by Carousel/ImageStack for cards
public protocol VisualRecording: Equatable, Identifiable {
    var id: String { get }
    var _index: Int { get }
    var title: String { get }
    var image: Image? { get }
    var color: Color { get }
    var imageWidth: CGFloat? { get }
    var imageHeight: CGFloat? { get }
}


// Compatibility with Blackbird: Codable, Equatable, Identifiable, Hashable, Sendable
/// Model representing a luxury asset
public struct Asset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: AssetCategory
    public let createdAt: Date
    public let tags: [String]
    public let thing: Things?
    public let evidence: [Evidence]
    public let thumbnailName: String?
    
    public private(set) var pieces: [EvidencePiece]
    
    public init(
        id: String,
        name: String,
        category: AssetCategory,
        createdAt: Date,
        tags: [String] = [],
        thing: Things? = nil,
        evidence: [Evidence] = [],
        pieces: [EvidencePiece] = [],
        thumbnailName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.createdAt = createdAt
        self.tags = tags
        self.thing = thing
        self.evidence = evidence
        self.pieces = pieces
        self.thumbnailName = thumbnailName
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
}

/// Categories for luxury assets
public enum AssetCategory: String, Codable, CaseIterable {
    case watches
    case bags
    case shoes
    case accessories
    case jewelry
    case clothing
    case other
    
    /// Display name for the category
    var displayName: String {
        switch self {
        case .watches: return "Watches"
        case .bags: return "Bags"
        case .shoes: return "Shoes"
        case .accessories: return "Accessories"
        case .jewelry: return "Jewelry"
        case .clothing: return "Clothing"
        case .other: return "Other"
        }
    }
    
    /// Icon name for the category
    var iconName: String {
        switch self {
        case .watches: return "clock.fill"
        case .bags: return "bag.fill"
        case .shoes: return "shoe.fill"
        case .accessories: return "eyeglasses"
        case .jewelry: return "sparkles"
        case .clothing: return "tshirt.fill"
        case .other: return "square.fill"
        }
    }
}

