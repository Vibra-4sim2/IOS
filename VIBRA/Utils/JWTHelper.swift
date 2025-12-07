//
//  JWTHelper.swift
//  VIBRA
//
//  Helper pour décoder le JWT et extraire l'ID utilisateur
//

import Foundation

struct JWTHelper {
    
    /// Décoder le JWT et extraire l'ID utilisateur
    static func getUserIdFromToken() -> String? {
        // Essayer de récupérer le token depuis le Keychain
        guard let token = try? KeychainManager.shared.getJWT() else {
            print("⚠️ JWTHelper: No JWT token found in Keychain")
            return nil
        }
        
        return extractUserId(from: token)
    }
    
    /// Extraire l'ID utilisateur depuis un token JWT
    static func extractUserId(from token: String) -> String? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else {
            print("❌ JWTHelper: Invalid JWT format")
            return nil
        }
        
        // Le payload est le second segment (index 1)
        let payloadSegment = segments[1]
        
        // Ajouter le padding si nécessaire pour le décodage Base64
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64.append(contentsOf: String(repeating: "=", count: paddingLength))
        }
        
        // Décoder le Base64
        guard let payloadData = Data(base64Encoded: base64) else {
            print("❌ JWTHelper: Failed to decode Base64 payload")
            return nil
        }
        
        // Parser le JSON
        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                // Chercher l'ID utilisateur (adapter selon votre JWT)
                // Les clés possibles : "userId", "user_id", "sub", "id"
                if let userId = json["userId"] as? String {
                    print("✅ JWTHelper: Found userId - \(userId)")
                    return userId
                } else if let userId = json["user_id"] as? String {
                    print("✅ JWTHelper: Found user_id - \(userId)")
                    return userId
                } else if let sub = json["sub"] as? String {
                    print("✅ JWTHelper: Found sub - \(sub)")
                    return sub
                } else if let id = json["id"] as? String {
                    print("✅ JWTHelper: Found id - \(id)")
                    return id
                } else {
                    print("⚠️ JWTHelper: No userId found in JWT payload")
                    print("📄 JWTHelper: JWT payload - \(json)")
                }
            }
        } catch {
            print("❌ JWTHelper: Failed to parse JWT payload - \(error)")
        }
        
        return nil
    }
    
    /// Sauvegarder l'ID utilisateur dans UserDefaults (alternative au décodage du JWT)
    static func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "currentUserId")
        print("✅ JWTHelper: Saved userId to UserDefaults - \(userId)")
    }
    
    /// Récupérer l'ID utilisateur depuis UserDefaults
    static func getUserIdFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: "currentUserId")
    }
    
    /// Supprimer l'ID utilisateur (lors de la déconnexion)
    static func clearUserId() {
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        print("🗑️ JWTHelper: Cleared userId from UserDefaults")
    }
}
