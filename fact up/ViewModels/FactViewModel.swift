import Foundation
import SwiftUI

@MainActor
class FactViewModel: ObservableObject {
    @Published var currentFact: Fact?
    @Published var favoriteFacts: [Fact] = []
    @Published var selectedCategory: FactCategory = .general
    @Published var backgroundColor: Color = .blue
    @Published var showingSettings = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isTranslating = false
    @Published var showTranslationOptions = false
    @Published var isSpeaking = false
    
    private var factHistory: [Fact] = []
    private var currentHistoryIndex = -1 // -1 means we're at the current fact (not in history)
    private let apiService = FactAPIService()
    private var nextFact: Fact? // Pre-fetched next fact
    private let translationService = TranslationService.shared
    private let speechService = SpeechService.shared
    private var speakingTimer: Timer?
    
    // UserDefaults keys
    private let favoritesKey = "savedFavorites"
    private let colorKey = "backgroundColor"
    
    init() {
        // Load saved favorites from UserDefaults
        loadFavorites()
        
        // Load saved background color
        loadBackgroundColor()
        
        // Load initial fact
        loadNewFact()
    }
    
    // MARK: - Persistence Methods
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey) {
            do {
                let decoder = JSONDecoder()
                let savedFacts = try decoder.decode([Fact].self, from: data)
                self.favoriteFacts = savedFacts
            } catch {
                print("Error loading favorites: \(error)")
            }
        }
    }
    
    private func saveFavorites() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favoriteFacts)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("Error saving favorites: \(error)")
        }
    }
    
    private func loadBackgroundColor() {
        if let colorData = UserDefaults.standard.data(forKey: colorKey) {
            do {
                let decoder = JSONDecoder()
                if let decodedColor = try? decoder.decode(CodableColor.self, from: colorData) {
                    self.backgroundColor = decodedColor.color
                }
            }
        }
    }
    
    private func saveBackgroundColor() {
        do {
            let encoder = JSONEncoder()
            let codableColor = CodableColor(color: backgroundColor)
            if let colorData = try? encoder.encode(codableColor) {
                UserDefaults.standard.set(colorData, forKey: colorKey)
            }
        }
    }
    
    // MARK: - Fact Loading Methods
    
    func loadNewFact() {
        Task {
            await fetchFactFromAPI()
        }
    }
    
    private func fetchFactFromAPI() async {
        isLoading = true
        errorMessage = nil
        
        // Add current fact to history if we have one and we're not already in history
        if let current = currentFact, currentHistoryIndex == -1 {
            factHistory.append(current)
        }
        
        do {
            // Use pre-fetched fact if available, otherwise fetch new one
            if let preFetched = nextFact {
                currentFact = preFetched
                nextFact = nil // Clear the pre-fetched fact
            } else {
                // Fetch fact based on selected category
                let newFact = try await apiService.fetchFactByCategory(selectedCategory.rawValue)
                currentFact = newFact
            }
            
            // Check if the new fact is in favorites and update its state
            if let current = currentFact {
                if favoriteFacts.contains(where: { $0.text == current.text }) {
                    currentFact = Fact(
                        text: current.text,
                        category: current.category,
                        isFavorite: true,
                        translatedText: current.translatedText,
                        translationLanguage: current.translationLanguage
                    )
                }
            }
            
            // Reset to current fact (not in history)
            currentHistoryIndex = -1
            
            // Pre-fetch the next fact for smooth experience
            await preFetchNextFact()
            
        } catch {
            // Handle API failure
            print("API Error: \(error)")
            errorMessage = "Failed to load fact from API. Please check your internet connection and try again."
            currentFact = nil
            currentHistoryIndex = -1
        }
        
        isLoading = false
    }
    
    private func preFetchNextFact() async {
        do {
            // Pre-fetch based on selected category
            let newFact = try await apiService.fetchFactByCategory(selectedCategory.rawValue)
            nextFact = newFact
        } catch {
            // If pre-fetch fails, we'll handle it when user actually swipes
            print("Pre-fetch error: \(error)")
        }
    }
    
    func loadPreviousFact() {
        guard !factHistory.isEmpty else { return }
        
        // If we're at the current fact, add it to history first
        if currentHistoryIndex == -1, let current = currentFact {
            factHistory.append(current)
        }
        
        // Navigate to the previous fact in history
        if currentHistoryIndex == -1 {
            // We're at the current fact, go to the last fact in history
            currentHistoryIndex = factHistory.count - 1
        } else if currentHistoryIndex > 0 {
            // We're in history, go to the previous fact
            currentHistoryIndex -= 1
        } else {
            // We're at the first fact in history, can't go back further
            return
        }
        
        // Set the current fact to the one from history
        currentFact = factHistory[currentHistoryIndex]
    }
    
    func canGoBack() -> Bool {
        // Can go back if we have history and we're not at the first fact
        return !factHistory.isEmpty && (currentHistoryIndex > 0 || currentHistoryIndex == -1)
    }
    
    func toggleFavorite() {
        guard var fact = currentFact else { return }
        fact = Fact(
            text: fact.text,
            category: fact.category,
            isFavorite: !fact.isFavorite,
            translatedText: fact.translatedText,
            translationLanguage: fact.translationLanguage
        )
        currentFact = fact
        
        if fact.isFavorite {
            favoriteFacts.append(fact)
        } else {
            favoriteFacts.removeAll { $0.text == fact.text }
        }
        
        // Save favorites to UserDefaults
        saveFavorites()
    }
    
    func shareFact() {
        guard let fact = currentFact else { return }
        let text = "Did you know? \(fact.text)\n\nShared from Fact Up!"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    func changeCategory(_ category: FactCategory) {
        selectedCategory = category
        // Clear history when changing category
        factHistory.removeAll()
        currentHistoryIndex = -1
        loadNewFact()
    }
    
    func changeBackgroundColor(_ color: Color) {
        backgroundColor = color
        saveBackgroundColor()
    }
    
    func clearHistory() {
        factHistory.removeAll()
        currentHistoryIndex = -1
    }
    
    // Debug method to help understand the current state
    func debugNavigationState() {
        print("=== Navigation Debug ===")
        print("Current fact: \(currentFact?.text.prefix(50) ?? "None")")
        print("History count: \(factHistory.count)")
        print("Current history index: \(currentHistoryIndex)")
        print("Can go back: \(canGoBack())")
        print("History facts:")
        for (index, fact) in factHistory.enumerated() {
            let marker = index == currentHistoryIndex ? " -> " : "    "
            print("\(marker)\(index): \(fact.text.prefix(50))")
        }
        if currentHistoryIndex == -1 {
            print(" -> Current fact (not in history)")
        }
        print("=======================")
    }
    
    // MARK: - Speech Methods
    
    func speakCurrentFact() {
        guard let fact = currentFact else { return }
        
        // Get the text to speak (translated or original)
        let textToSpeak = fact.translatedText ?? fact.text
        
        // Get the language code for speech
        let languageCode = speechService.getLanguageCodeForSpeech(from: currentTranslationLanguage)
        
        // Start speaking
        speechService.speak(text: textToSpeak, language: languageCode)
        isSpeaking = true
        
        // Cancel any existing timer
        speakingTimer?.invalidate()
        
        // Monitor speaking status using a main actor-safe approach
        speakingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if !self.speechService.isSpeaking() {
                    self.isSpeaking = false
                    self.speakingTimer?.invalidate()
                    self.speakingTimer = nil
                }
            }
        }
    }
    
    func stopSpeaking() {
        speechService.stopSpeaking()
        isSpeaking = false
        speakingTimer?.invalidate()
        speakingTimer = nil
    }
    
    // MARK: - Translation Methods
    
    func translateCurrentFact(to language: TranslationLanguage) {
        guard let fact = currentFact else { return }
        
        // If already translated to this language, just show the translation
        if fact.translationLanguage == language.rawValue, let translatedText = fact.translatedText {
            updateCurrentFactWithTranslation(translatedText, language: language)
            return
        }
        
        // Otherwise, perform the translation
        isTranslating = true
        
        Task {
            if let translatedText = await translationService.translateText(fact.text, to: language) {
                updateCurrentFactWithTranslation(translatedText, language: language)
            } else {
                // Handle translation error
                errorMessage = "Failed to translate. Please try again."
            }
            isTranslating = false
        }
    }
    
    private func updateCurrentFactWithTranslation(_ translatedText: String, language: TranslationLanguage) {
        guard var fact = currentFact else { return }
        
        // Update the current fact with the translation
        fact.translatedText = translatedText
        fact.translationLanguage = language.rawValue
        currentFact = fact
        
        // If we're viewing a fact from history, update it there too
        if currentHistoryIndex >= 0 && currentHistoryIndex < factHistory.count {
            factHistory[currentHistoryIndex].translatedText = translatedText
            factHistory[currentHistoryIndex].translationLanguage = language.rawValue
        }
    }
    
    func resetTranslation() {
        guard var fact = currentFact else { return }
        
        // Clear the translation
        fact.translatedText = nil
        fact.translationLanguage = nil
        currentFact = fact
        
        // If we're viewing a fact from history, update it there too
        if currentHistoryIndex >= 0 && currentHistoryIndex < factHistory.count {
            factHistory[currentHistoryIndex].translatedText = nil
            factHistory[currentHistoryIndex].translationLanguage = nil
        }
    }
    
    // Check if the current fact is translated
    var isCurrentFactTranslated: Bool {
        guard let fact = currentFact else { return false }
        return fact.translatedText != nil
    }
    
    // Get the current translation language if any
    var currentTranslationLanguage: TranslationLanguage? {
        guard let fact = currentFact, let languageCode = fact.translationLanguage else { return nil }
        return TranslationLanguage(rawValue: languageCode)
    }
    
    // MARK: - Favorite Management
    
    func removeFavorite(at index: Int) {
        if index < favoriteFacts.count {
            let removedFact = favoriteFacts[index]
            favoriteFacts.remove(at: index)
            
            // If the current fact is the one being unfavorited, update it
            if let current = currentFact, current.text == removedFact.text {
                currentFact = Fact(
                    text: current.text,
                    category: current.category,
                    isFavorite: false,
                    translatedText: current.translatedText,
                    translationLanguage: current.translationLanguage
                )
            }
            
            // Save the updated favorites
            saveFavorites()
        }
    }
}

// Helper struct to make Color codable
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.opacity = Double(alpha)
    }
    
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
} 