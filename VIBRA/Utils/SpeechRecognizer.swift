//
//  SpeechRecognizer.swift
//  VIBRA
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    errorMessage = "Permission de reconnaissance vocale refusée"
                    return
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    errorMessage = "Permission d'enregistrement audio refusée"
                    return
                }
            } catch {
                errorMessage = "Erreur d'initialisation: \(error.localizedDescription)"
            }
        }
    }
    
    deinit {
        task?.cancel()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    errorMessage = "Permission de reconnaissance vocale refusée"
                    return
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    errorMessage = "Permission d'enregistrement audio refusée"
                    return
                }
            } catch {
                errorMessage = "Erreur de permissions: \(error.localizedDescription)"
                return
            }
            
            await transcribe()
        }
    }
    
    func stopRecording() {
        reset()
    }
    
    private func transcribe() async {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "Reconnaissance vocale non disponible"
            return
        }
        
        do {
            let (audioEngine, request) = try prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            self.isRecording = true
            
            self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let result = result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    
                    if error != nil || result?.isFinal == true {
                        self.reset()
                    }
                }
            }
        } catch {
            self.reset()
            self.errorMessage = "Erreur de transcription: \(error.localizedDescription)"
        }
    }
    
    private func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        
        audioEngine = nil
        request = nil
        task = nil
        isRecording = false
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}
