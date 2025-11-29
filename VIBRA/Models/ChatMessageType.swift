//
//  ChatMessageType.swift
//  VIBRA
//
//  Created by mac book pro on 11/29/25.
//

//
//  ChatMessageType.swift
//  VIBRA
//

import Foundation

enum ChatMessageType22: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"      // Message vocal
    case file = "file"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .text: return "Texte"
        case .image: return "Image"
        case .video: return "Vidéo"
        case .audio: return "Message vocal"
        case .file: return "Fichier"
        case .system: return "Système"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .file: return "doc"
        case .system: return "info.circle"
        }
    }
}
