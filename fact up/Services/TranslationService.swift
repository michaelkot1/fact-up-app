import Foundation
import SwiftUI

class TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    // Check if translation is available
    var isTranslationAvailable: Bool {
        return true // Always available with our API approach
    }
    
    // Translate text using Google Translate API
    func translateText(_ text: String, to language: TranslationLanguage) async -> String? {
        do {
            // URL encode the text
            guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return fallbackTranslate(text, to: language)
            }
            
            // Create URL for Google Translate API
            let urlString = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=\(language.rawValue)&dt=t&q=\(encodedText)"
            
            guard let url = URL(string: urlString) else {
                return fallbackTranslate(text, to: language)
            }
            
            // Create URL request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Add headers to make it look like a browser request
            request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for valid response
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response from translation API")
                return fallbackTranslate(text, to: language)
            }
            
            // Parse the JSON response
            // The response format is a nested array: [[[translated text, original text, ...], ...], ...]
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any],
               let textArray = jsonArray[0] as? [Any] {
                
                // Combine all translated parts
                var translatedText = ""
                
                for item in textArray {
                    if let translationArray = item as? [Any], 
                       let translationPart = translationArray[0] as? String {
                        translatedText += translationPart
                    }
                }
                
                if !translatedText.isEmpty {
                    return translatedText
                }
            }
            
            print("Failed to parse translation response")
            return fallbackTranslate(text, to: language)
            
        } catch {
            print("Translation error: \(error)")
            return fallbackTranslate(text, to: language)
        }
    }
    
    // Simple fallback translation for when the API fails
    private func fallbackTranslate(_ text: String, to language: TranslationLanguage) -> String {
        // This is just a placeholder - in a real app, you might use a different API
        let prefix: String
        switch language {
        case .spanish:
            prefix = "[ES] "
        case .russian:
            prefix = "[RU] "
        case .swedish:
            prefix = "[SV] "
        }
        
        return prefix + text
    }
} 