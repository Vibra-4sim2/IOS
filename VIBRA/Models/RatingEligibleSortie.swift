//
//  RatingEligibleSortie.swift
//  VIBRA
//

import Foundation

struct RatingEligibleSortie: Codable, Identifiable {
    // Backend JSON has no explicit id field; use sortieId as identifier
    var id: String { sortieId }
    let sortieId: String
    let title: String
    let camping: Bool
    let eligibleDate: String
}

struct SubmitSortieRatingRequest: Codable {
    let stars: Int
    let comment: String?
}
