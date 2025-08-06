import Foundation
import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    private init() {}
    
    func speak(text: String, language: String? = nil) {
        // Stop any ongoing speech
        stopSpeaking()
        
        // Create a new utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Set the language if provided, otherwise use system default
        if let languageCode = language {
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        }
        
        // Configure speech parameters
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Store reference to current utterance
        currentUtterance = utterance
        
        // Speak the text
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentUtterance = nil
    }
    
    func isSpeaking() -> Bool {
        return synthesizer.isSpeaking
    }
    
    // Get appropriate language code for speech based on translation language
    func getLanguageCodeForSpeech(from translationLanguage: TranslationLanguage?) -> String? {
        guard let language = translationLanguage else {
            return nil // Use system default
        }
        
        switch language {
        case .spanish:
            return "es-ES"
        case .russian:
            return "ru-RU"
        case .swedish:
            return "sv-SE"
        }
    }
} 