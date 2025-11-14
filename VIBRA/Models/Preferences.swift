//
//  Preferences.swift
//  VIBRA
//

import Foundation

// Conserver exactement les valeurs de string attendues par le backend
enum Level: String, Codable, CaseIterable, Identifiable, Hashable {
    case BEGINNER
    case INTERMEDIATE
    case ADVANCED
    var id: String { rawValue }
}

// Cycling
enum CyclingType: String, Codable, CaseIterable, Identifiable, Hashable {
    case VTT
    case ROUTE
    case GRAVEL
    case URBAIN
    case ELECTRIQUE
    var id: String { rawValue }
}
enum CyclingFrequency: String, Codable, CaseIterable, Identifiable, Hashable {
    case QUOTIDIEN
    case HEBDO
    case WEEKEND
    case RARE
    var id: String { rawValue }
}
enum CyclingDistance: String, Codable, CaseIterable, Identifiable, Hashable {
    case lessThan10 = "<10"
    case between10_30 = "10-30"
    case between30_60 = "30-60"
    case greaterThan60 = ">60"
    var id: String { rawValue }
}

// Hike
enum HikeType: String, Codable, CaseIterable, Identifiable, Hashable {
    case COURTE
    case MONTAGNE
    case LONGUE
    case TREKKING
    var id: String { rawValue }
}
enum HikeDuration: String, Codable, CaseIterable, Identifiable, Hashable {
    case less2H = "<2H"
    case h2_4 = "2-4H"
    case h4_8 = "4-8H"
    case greater8H = ">8H"
    var id: String { rawValue }
}
enum HikePreference: String, Codable, CaseIterable, Identifiable, Hashable {
    case GROUPE
    case SEUL
    var id: String { rawValue }
}

// Camping
enum CampingType: String, Codable, CaseIterable, Identifiable, Hashable {
    case TENTE
    case VAN
    case CAMPING_CAR = "CAMPING-CAR" // Swift-friendly case name, raw value matches backend
    case REFUGE
    case BIVOUAC
    var id: String { rawValue }
}
enum CampingDuration: String, Codable, CaseIterable, Identifiable, Hashable {
    case _1NUIT = "1NUIT"
    case WEEKEND = "WEEKEND"
    case _3_5J = "3-5J"
    case greater1WEEK = ">1SEMAINE"
    var id: String { rawValue }
}

// Main model — utiliser des optionals pour n'envoyer que les champs définis
struct Preferences: Codable {
    var _id: String?
    var user: String?
    var level: Level?
    
    // Cycling
    var cyclingType: CyclingType?
    var cyclingFrequency: CyclingFrequency?
    var cyclingDistance: CyclingDistance?
    var cyclingGroupInterest: Bool?
    
    // Hike
    var hikeType: HikeType?
    var hikeDuration: HikeDuration?
    var hikePreference: HikePreference?
    
    // Camping
    var campingPractice: Bool?
    var campingType: CampingType?
    var campingDuration: CampingDuration?
    
    // Other server fields
    var onboardingComplete: Bool?
}
