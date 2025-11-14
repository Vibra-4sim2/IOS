//
//  AuthService.swift
//  VIBRA
//
//  Created by mac book pro on 11/7/25.
//

import Foundation

// MARK: - AuthService
final class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    // MARK: - LOGIN
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(Constants.baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Server error \(httpResponse.statusCode): \(serverMessage)")
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    // MARK: - REGISTER
    func register(firstName: String,
                  lastName: String,
                  gender: String,
                  email: String,
                  password: String,
                  avatar: String? = nil,
                  role: String? = nil) async throws -> User {
        
        guard let url = URL(string: "\(Constants.baseURL)/user") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "Gender": gender, // ✅ correspond au backend
            "email": email,
            "password": password
        ]
        
        if let avatar = avatar { body["avatar"] = avatar }
        if let role = role { body["role"] = role }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Server error \(httpResponse.statusCode): \(serverMessage)")
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - FORGOT PASSWORD
    func forgotPassword(email: String) async throws -> ServerMessage {
        guard let url = URL(string: "\(Constants.baseURL)/auth/forgot-password") else {
            throw URLError(.badURL)
        }
        
        let body = ["email": email]
        return try await performPostRequest(url: url, body: body)
    }
    
    // MARK: - VERIFY RESET CODE
    func verifyResetCode(email: String, code: String) async throws -> ServerMessage {
        guard let url = URL(string: "\(Constants.baseURL)/auth/verify-reset-code") else {
            throw URLError(.badURL)
        }
        
        let body = ["email": email, "code": code]
        return try await performPostRequest(url: url, body: body)
    }
    
    // MARK: - RESET PASSWORD
    func resetPassword(email: String, code: String, newPassword: String) async throws -> ServerMessage {
        guard let url = URL(string: "\(Constants.baseURL)/auth/reset-password") else {
            throw URLError(.badURL)
        }
        
        let body = ["email": email, "code": code, "newPassword": newPassword]
        return try await performPostRequest(url: url, body: body)
    }
    
    // MARK: - GENERIC POST
    private func performPostRequest(url: URL, body: [String: String]) async throws -> ServerMessage {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Server error: \(serverMessage)")
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(ServerMessage.self, from: data)
    }
    // MARK: - get user by id
    func getUser(byId id: String) async throws -> User {
            guard let url = URL(string: "\(Constants.baseURL)/user/\(id)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Ajouter le token si disponible
            if let token = try? KeychainManager.shared.getJWT() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Server error: \(serverMessage)")
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(User.self, from: data)
        }
    // MARK: - UPDATE USER
        func updateUser(userId: String, updatedUser: UpdateUserRequest) async throws -> User {
            guard let url = URL(string: "\(Constants.baseURL)/user/\(userId)") else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = try? KeychainManager.shared.getJWT() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try JSONEncoder().encode(updatedUser)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw URLError(.badServerResponse)
            }
            return try JSONDecoder().decode(User.self, from: data)
        }
}

// MARK: - Response Models
struct ServerMessage: Codable {
    let message: String
}

// MARK: - DTO pour update
struct UpdateUserRequest: Codable {
    var firstName: String
    var lastName: String
    var gender: String
    var email: String
    var avatar: String?
    var password: String
}
