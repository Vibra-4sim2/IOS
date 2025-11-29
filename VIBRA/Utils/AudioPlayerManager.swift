//
//  AudioPlayerManager.swift
//  VIBRA
//
//  Gestionnaire de lecture audio pour les messages vocaux
//

import Foundation
import AVFoundation
import Combine

final class AudioPlayerManager: NSObject, ObservableObject {
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentlyPlayingId: String?
    @Published var isLoading = false
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    override init() {
        super.init()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Playback
    
    @MainActor
    func play(url: URL, messageId: String) async throws {
        print("🔊 [AudioPlayer] play called for messageId:", messageId)
        print("🔊 [AudioPlayer] URL:", url.absoluteString)
        
        // Si on joue déjà ce message, toggle pause/play
        if currentlyPlayingId == messageId, let player = audioPlayer {
            print("🔊 [AudioPlayer] Toggling playback for same message")
            if player.isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }
        
        // Sinon, arrêter l'ancien et démarrer le nouveau
        stop()
        
        isLoading = true
        defer { isLoading = false }
        
        // Télécharger le fichier si c'est une URL distante
        let localURL: URL
        if url.isFileURL {
            print("🔊 [AudioPlayer] Local file")
            localURL = url
        } else {
            print("🔊 [AudioPlayer] Remote file, downloading...")
            localURL = try await downloadAudio(from: url)
            print("🔊 [AudioPlayer] Download complete:", localURL.path)
        }
        
        // Configuration de la session audio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        
        // Création du player
        print("🔊 [AudioPlayer] Creating AVAudioPlayer...")
        audioPlayer = try AVAudioPlayer(contentsOf: localURL)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        duration = audioPlayer?.duration ?? 0
        currentTime = 0
        currentlyPlayingId = messageId
        
        print("🔊 [AudioPlayer] Duration:", duration)
        
        // Démarrage
        let started = audioPlayer?.play() ?? false
        print("🔊 [AudioPlayer] Play started:", started)
        isPlaying = started
        
        if started {
            // Timer pour le suivi de la progression
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                Task { @MainActor in
                    self.currentTime = player.currentTime
                }
            }
        }
    }
    
    private func downloadAudio(from url: URL) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ [AudioPlayer] Download failed with response:", response)
            throw AudioPlayerError.downloadFailed
        }
        
        print("🔊 [AudioPlayer] Downloaded \(data.count) bytes")
        
        // Sauvegarder dans un fichier temporaire
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "audio-\(Int(Date().timeIntervalSince1970)).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        print("🔊 [AudioPlayer] Saved to:", fileURL.path)
        
        return fileURL
    }
    
    func pause() {
        print("🔊 [AudioPlayer] Pause")
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func resume() {
        print("🔊 [AudioPlayer] Resume")
        audioPlayer?.play()
        isPlaying = true
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            Task { @MainActor in
                self.currentTime = player.currentTime
            }
        }
    }
    
    func stop() {
        print("🔊 [AudioPlayer] Stop")
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentlyPlayingId = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
    }
    
    // MARK: - Helpers
    
    func isPlayingMessage(_ messageId: String) -> Bool {
        return currentlyPlayingId == messageId && isPlaying
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔊 [AudioPlayer] Finished playing, success:", flag)
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [AudioPlayer] Decode error:", error?.localizedDescription ?? "unknown")
        DispatchQueue.main.async { [weak self] in
            self?.stop()
        }
    }
}

// MARK: - Errors

enum AudioPlayerError: LocalizedError {
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Échec du téléchargement du fichier audio"
        }
    }
}
