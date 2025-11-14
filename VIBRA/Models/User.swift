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
    let gender: String        // correspond à "Gender" dans le backend
    let email: String
    let birthday: String?     // nouveau champ optionnel
    let avatar: String?
    let role: String
    let password: String?     // utilisé seulement lors de la création

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
        case lastName
        case gender = "Gender"    // Backend utilise "Gender" avec majuscule
        case email
        case birthday             // Backend renvoie "birthday"
        case avatar
        case role
        case password
    }
}
