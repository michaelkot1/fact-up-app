import Foundation

struct Fact: Identifiable, Codable {
    let id = UUID()
    let text: String
    let category: String
    let isFavorite: Bool
    var translatedText: String? // Store translated version of the fact
    var translationLanguage: String? // Store which language the translation is in
    
    init(text: String, category: String, isFavorite: Bool = false, translatedText: String? = nil, translationLanguage: String? = nil) {
        self.text = text
        self.category = category
        self.isFavorite = isFavorite
        self.translatedText = translatedText
        self.translationLanguage = translationLanguage
    }
    
    // Custom Codable implementation to handle UUID
    enum CodingKeys: String, CodingKey {
        case text, category, isFavorite, translatedText, translationLanguage
    }
}

enum FactCategory: String, CaseIterable {
    case general = "General"
    case random = "Random"
    case interesting = "Interesting"
    case surprising = "Surprising"
    case animals = "Animals"
    case history = "History"
    case science = "Science"
    
    var displayName: String {
        return self.rawValue
    }
}

// Supported translation languages
enum TranslationLanguage: String, CaseIterable, Identifiable, Codable {
    case spanish = "es"
    case russian = "ru"
    case swedish = "sv"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .spanish: return "Spanish"
        case .russian: return "Russian"
        case .swedish: return "Swedish"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .spanish: return "es"
        case .russian: return "ru"
        case .swedish: return "sv"
        }
    }
} 