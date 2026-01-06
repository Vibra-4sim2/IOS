//
//  ConversationService.swift
//  VIBRA
//
//  Service for uploading media files for private messages
//

import Foundation
import UIKit

final class ConversationService {
    static let shared = ConversationService()
    private init() {}
    
    private var baseURL: String { Constants.baseURL }
    
    // MARK: - Upload Image
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ConversationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        uploadMedia(data: imageData, fileName: "image.jpg", mimeType: "image/jpeg", endpoint: "/conversations/upload/image", completion: completion)
    }
    
    // MARK: - Upload Audio
    
    func uploadAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let audioData = try Data(contentsOf: fileURL)
            uploadMedia(data: audioData, fileName: "audio.m4a", mimeType: "audio/m4a", endpoint: "/conversations/upload/audio", completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Private Upload Helper
    
    private func uploadMedia(data: Data, fileName: String, mimeType: String, endpoint: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "ConversationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header
        if let token = try? KeychainManager.shared.getJWT() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "ConversationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let url = json["url"] as? String {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "ConversationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
