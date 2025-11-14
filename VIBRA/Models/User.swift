//
//  User.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//

struct User: Codable {
    let id: String?
    let firstName: String
    let lastName: String
    let gender: String
    let email: String
    let avatar: String?
    let role: String

    // Mapping pour correspondre aux noms exacts renvoyés par le backend
    enum CodingKeys: String, CodingKey {
        case id = "_id"         // MongoDB renvoie l’ID sous _id
        case firstName
        case lastName
        case gender = "Gender"  // Backend utilise "Gender" avec majuscule
        case email
        case avatar
        case role
    }
}
