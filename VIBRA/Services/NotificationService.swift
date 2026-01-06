//
//  NotificationService.swift
//  VIBRA
//
//  HTTP polling notification service (no FCM)
//

import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    private var baseURL: String { Constants.baseURL }
    
    // MARK: - Get Notifications (Polling)
    
    func getNotifications(unreadOnly: Bool = true, limit: Int = 50, offset: Int = 0) async throws -> [AppNotification] {
        guard let token = try? KeychainManager.shared.getJWT() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var components = URLComponents(string: "\(baseURL)/notifications")!
        components.queryItems = [
            URLQueryItem(name: "unreadOnly", value: String(unreadOnly)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Get notifications failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        // Decode array of notifications directly
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let notifications = try decoder.decode([AppNotification].self, from: data)
        
        return notifications
    }
    
    // MARK: - Get Unread Count
    
    func getUnreadCount() async throws -> Int {
        guard let token = try? KeychainManager.shared.getJWT() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/notifications/unread-count") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Get unread count failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["count"] as? Int ?? 0
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(notificationId: String) async throws {
        guard let token = try? KeychainManager.shared.getJWT() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Mark as read failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Mark All as Read
    
    func markAllAsRead(notificationIds: [String]) async throws {
        // Call markAsRead for each notification concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for id in notificationIds {
                group.addTask {
                    try await self.markAsRead(notificationId: id)
                }
            }
            try await group.waitForAll()
        }
    }
}
