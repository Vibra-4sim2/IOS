//
//  AudioRecorderManager.swift
//  VIBRA
//
//  Gestionnaire d'enregistrement audio pour les messages vocaux
//

import Foundation
import AVFoundation
import Combine

final class AudioRecorderManager: NSObject, ObservableObject {
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    override init() {
        super.init()
        Task { @MainActor in
            await checkPermission()
        }
    }
    
    // MARK: - Permissions
    
    @MainActor
    func checkPermission() async {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            await requestPermission()
        @unknown default:
            hasPermission = false
        }
    }
    
    @MainActor
    func requestPermission() async {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasPermission = granted
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Recording
    
    @MainActor
    func startRecording() throws -> URL {
        print("🎙️ [AudioRecorder] startRecording called")
        print("🎙️ [AudioRecorder] hasPermission:", hasPermission)
        print("🎙️ [AudioRecorder] isRecording before:", isRecording)
        
        guard hasPermission else {
            print("❌ [AudioRecorder] No permission")
            throw AudioRecorderError.noPermission
        }
        
        // Configuration de la session audio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        
        // Création du fichier temporaire
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice-\(Int(Date().timeIntervalSince1970)).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Configuration de l'enregistrement (AAC, 128kbps)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Création de l'enregistreur
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
        
        // Démarrage
        guard audioRecorder?.record() == true else {
            print("❌ [AudioRecorder] Failed to start recording")
            throw AudioRecorderError.recordingFailed
        }
        
        print("✅ [AudioRecorder] Recording started successfully")
        
        // IMPORTANT: Mettre à jour isRecording APRÈS le démarrage réussi
        isRecording = true
        recordingStartTime = Date()
        recordingDuration = 0
        
        print("🎙️ [AudioRecorder] isRecording after:", isRecording)
        
        // Timer pour la durée
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
        
        return fileURL
    }
    
    @MainActor
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard isRecording, let recorder = audioRecorder else { return nil }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        recorder.stop()
        isRecording = false
        
        let url = recorder.url
        let duration = recordingDuration
        
        // Désactivation de la session audio
        try? AVAudioSession.sharedInstance().setActive(false)
        
        audioRecorder = nil
        recordingStartTime = nil
        
        return (url, duration)
    }
    
    @MainActor
    func cancelRecording() {
        guard isRecording, let recorder = audioRecorder else { return }
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        let fileURL = recorder.url
        recorder.stop()
        recorder.deleteRecording()
        
        // Suppression manuelle si nécessaire
        try? FileManager.default.removeItem(at: fileURL)
        
        isRecording = false
        recordingDuration = 0
        audioRecorder = nil
        recordingStartTime = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - Validation
    
    func validateRecording(url: URL, duration: TimeInterval) throws {
        // Durée minimale : 1 seconde
        guard duration >= 1.0 else {
            throw AudioRecorderError.tooShort
        }
        
        // Durée maximale : 5 minutes
        guard duration <= 300.0 else {
            throw AudioRecorderError.tooLong
        }
        
        // Vérification que le fichier existe
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioRecorderError.fileNotFound
        }
        
        // Vérification de la taille (max 10MB)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            guard fileSize <= 10 * 1024 * 1024 else {
                throw AudioRecorderError.fileTooLarge
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("⚠️ Recording failed")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording error:", error?.localizedDescription ?? "unknown")
        cancelRecording()
    }
}

// MARK: - Errors

enum AudioRecorderError: LocalizedError {
    case noPermission
    case recordingFailed
    case tooShort
    case tooLong
    case fileNotFound
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .noPermission:
            return "Permission d'accès au microphone refusée"
        case .recordingFailed:
            return "Échec du démarrage de l'enregistrement"
        case .tooShort:
            return "L'enregistrement doit durer au moins 1 seconde"
        case .tooLong:
            return "L'enregistrement ne peut pas dépasser 5 minutes"
        case .fileNotFound:
            return "Fichier audio introuvable"
        case .fileTooLarge:
            return "Le fichier audio est trop volumineux (max 10MB)"
        }
    }
}
