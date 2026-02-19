//
//  Season.swift
//  TripFit
//
//  Created by bbdyno on 2/19/26.
//

import Foundation

public enum Season: String, CaseIterable, Codable {
    case spring
    case summer
    case fall
    case winter
    case all

    public var displayName: String {
        switch self {
        case .spring: "Spring"
        case .summer: "Summer"
        case .fall: "Fall"
        case .winter: "Winter"
        case .all: "All Seasons"
        }
    }
}
