//
//  ConversationUser.swift
//  VIBRA
//
//  User model for private messaging
//

import Foundation

struct ConversationUser: Identifiable, Codable, Hashable {
    let id: String
    let name: String?  // Optional - backend might not send it
    let email: String
    let avatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
        case avatar
    }
    
    // Computed property for display name (fallback to email if name missing)
    var displayName: String {
        return name ?? email.components(separatedBy: "@").first ?? email
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConversationUser, rhs: ConversationUser) -> Bool {
        lhs.id == rhs.id
    }
}
