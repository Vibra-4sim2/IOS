//
//  RideWithCreator.swift
//  VIBRA
//
//  Created by mac book pro on 11/16/25.
//

import Foundation

struct RideWithCreator: Identifiable, Hashable {
    let id: String
    let ride: Ride
    var creator: User?

    init(ride: Ride, creator: User?) {
        self.ride = ride
        self.creator = creator
        self.id = ride.id ?? UUID().uuidString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RideWithCreator, rhs: RideWithCreator) -> Bool {
        lhs.id == rhs.id
    }
}
