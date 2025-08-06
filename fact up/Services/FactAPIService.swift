import Foundation

// MARK: - Useless Facts API Response
struct UselessFactResponse: Codable {
    let id: String
    let text: String
    let source: String
    let source_url: String
    let language: String
    let permalink: String
}

// MARK: - API Ninjas Fact Response
struct NinjaFactResponse: Codable {
    let fact: String
}

// MARK: - Fact API Service
class FactAPIService: ObservableObject {
    private let uselessFactsURL = "https://uselessfacts.jsph.pl/api/v2/facts/random"
    private let ninjaFactsURL = "https://api.api-ninjas.com/v1/facts"
    private let ninjaAPIKey = "rlDcFkgY1xxj/EyWyUIXGw==j1KGDs2FqtMfFJpt"
    
    // Cache of recent facts to avoid duplicates
    private var recentFacts: [String] = []
    private let maxCacheSize = 50
    
    enum APIError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError(String)
        case categoryNotFound
    }
    
    // MARK: - Fetch Random Fact from Useless Facts API
    func fetchRandomFact() async throws -> Fact {
        guard let url = URL(string: uselessFactsURL) else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let uselessResponse = try JSONDecoder().decode(UselessFactResponse.self, from: data)
            
            // Cache the fact to avoid duplicates
            addToRecentFacts(uselessResponse.text)
            
            return Fact(
                text: uselessResponse.text,
                category: "General", // All facts are general since API doesn't support categories
                isFavorite: false
            )
        } catch {
            if error is DecodingError {
                throw APIError.decodingError
            } else {
                throw APIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Fetch Fact from API Ninjas
    func fetchNinjaFact(limit: Int = 1) async throws -> [Fact] {
        // API Ninjas doesn't allow limit parameter for free accounts
        guard let url = URL(string: ninjaFactsURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(ninjaAPIKey, forHTTPHeaderField: "X-Api-Key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let ninjaResponse = try JSONDecoder().decode([NinjaFactResponse].self, from: data)
            
            // Cache the facts to avoid duplicates
            for response in ninjaResponse {
                addToRecentFacts(response.fact)
            }
            
            return ninjaResponse.map { Fact(
                text: $0.fact,
                category: "General", // API Ninjas doesn't provide categories
                isFavorite: false
            )}
        } catch {
            if error is DecodingError {
                throw APIError.decodingError
            } else {
                throw APIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Fetch Fact by Category (simulated categories using different APIs)
    func fetchFactByCategory(_ category: String) async throws -> Fact {
        switch category {
        case "General":
            return try await fetchRandomFact()
            
        case "Random", "Interesting", "Surprising":
            // For these categories, we'll use API Ninjas
            let facts = try await fetchNinjaFact()
            if let fact = facts.first {
                return fact
            }
            // If API Ninjas fails, try Useless Facts API
            return try await fetchRandomFact()
            
        case "Animals":
            // Try up to 15 times to get an animal fact
            for _ in 0..<15 {
                // Try to get a fact from Useless Facts API first
                let fact = try await fetchRandomFact()
                
                // Check if it contains animal keywords
                let animalKeywords = [
                    "animal", "dog", "cat", "bird", "fish", "pet", "wildlife", "species", 
                    "creature", "zoo", "mammal", "reptile", "insect", "bear", "lion", "tiger", 
                    "elephant", "monkey", "ape", "gorilla", "whale", "dolphin", "shark", "octopus",
                    "squid", "snake", "lizard", "frog", "toad", "horse", "cow", "pig", "sheep",
                    "goat", "chicken", "duck", "goose", "bee", "ant", "spider", "butterfly"
                ]
                
                let isAnimalFact = animalKeywords.contains { keyword in
                    fact.text.lowercased().contains(keyword.lowercased())
                }
                
                if isAnimalFact {
                    return Fact(text: fact.text, category: "Animals", isFavorite: false)
                }
            }
            
            // If no animal fact found after 15 tries, try API Ninjas
            for _ in 0..<5 {
                let ninjaFacts = try await fetchNinjaFact()
                if let fact = ninjaFacts.first {
                    // Check if it contains animal keywords
                    let animalKeywords = [
                        "animal", "dog", "cat", "bird", "fish", "pet", "wildlife", "species", 
                        "creature", "zoo", "mammal", "reptile", "insect", "bear", "lion", "tiger", 
                        "elephant", "monkey", "ape", "gorilla", "whale", "dolphin", "shark", "octopus",
                        "squid", "snake", "lizard", "frog", "toad", "horse", "cow", "pig", "sheep",
                        "goat", "chicken", "duck", "goose", "bee", "ant", "spider", "butterfly"
                    ]
                    
                    let isAnimalFact = animalKeywords.contains { keyword in
                        fact.text.lowercased().contains(keyword.lowercased())
                    }
                    
                    if isAnimalFact {
                        return Fact(text: fact.text, category: "Animals", isFavorite: false)
                    }
                }
            }
            
            // If still no match, return a random fact with Animals category
            let randomFact = try await fetchRandomFact()
            return Fact(text: randomFact.text, category: "Animals", isFavorite: false)
            
        case "History":
            // Try up to 15 times to get a history fact
            for _ in 0..<15 {
                // Try to get a fact from Useless Facts API first
                let fact = try await fetchRandomFact()
                
                // Check if it contains history keywords
                let historyKeywords = [
                    "history", "ancient", "century", "year", "war", "king", "queen", "president",
                    "empire", "civilization", "dynasty", "ruler", "throne", "kingdom", "revolution",
                    "medieval", "renaissance", "prehistoric", "artifact", "archaeology", "historical",
                    "BC", "AD", "BCE", "CE", "era", "period", "age", "decade", "millennium", "castle",
                    "palace", "monument", "ruins", "heritage", "ancestor", "descendant", "dynasty",
                    "conquest", "explorer", "discovery", "expedition", "colony", "settlement"
                ]
                
                let isHistoryFact = historyKeywords.contains { keyword in
                    fact.text.lowercased().contains(keyword.lowercased())
                }
                
                if isHistoryFact {
                    return Fact(text: fact.text, category: "History", isFavorite: false)
                }
            }
            
            // If no history fact found after 15 tries, try API Ninjas
            for _ in 0..<5 {
                let ninjaFacts = try await fetchNinjaFact()
                if let fact = ninjaFacts.first {
                    // Check if it contains history keywords
                    let historyKeywords = [
                        "history", "ancient", "century", "year", "war", "king", "queen", "president",
                        "empire", "civilization", "dynasty", "ruler", "throne", "kingdom", "revolution",
                        "medieval", "renaissance", "prehistoric", "artifact", "archaeology", "historical",
                        "BC", "AD", "BCE", "CE", "era", "period", "age", "decade", "millennium", "castle",
                        "palace", "monument", "ruins", "heritage", "ancestor", "descendant", "dynasty",
                        "conquest", "explorer", "discovery", "expedition", "colony", "settlement"
                    ]
                    
                    let isHistoryFact = historyKeywords.contains { keyword in
                        fact.text.lowercased().contains(keyword.lowercased())
                    }
                    
                    if isHistoryFact {
                        return Fact(text: fact.text, category: "History", isFavorite: false)
                    }
                }
            }
            
            // If still no match, return a random fact with History category
            let randomFact = try await fetchRandomFact()
            return Fact(text: randomFact.text, category: "History", isFavorite: false)
            
        case "Science":
            // Try up to 15 times to get a science fact
            for _ in 0..<15 {
                // Try to get a fact from Useless Facts API first
                let fact = try await fetchRandomFact()
                
                // Check if it contains science keywords
                let scienceKeywords = [
                    "science", "physics", "chemistry", "biology", "space", "planet", "atom", "research",
                    "scientist", "laboratory", "experiment", "theory", "hypothesis", "discovery",
                    "invention", "technology", "innovation", "engineering", "quantum", "molecular",
                    "cell", "DNA", "RNA", "gene", "genome", "protein", "enzyme", "bacteria", "virus",
                    "solar", "lunar", "stellar", "cosmic", "galaxy", "universe", "astronomy", "telescope",
                    "microscope", "element", "compound", "reaction", "molecule", "particle", "electron",
                    "proton", "neutron", "isotope", "radiation", "energy", "force", "gravity", "magnetic",
                    "electric", "current", "voltage", "frequency", "wavelength", "spectrum"
                ]
                
                let isScienceFact = scienceKeywords.contains { keyword in
                    fact.text.lowercased().contains(keyword.lowercased())
                }
                
                if isScienceFact {
                    return Fact(text: fact.text, category: "Science", isFavorite: false)
                }
            }
            
            // If no science fact found after 15 tries, try API Ninjas
            for _ in 0..<5 {
                let ninjaFacts = try await fetchNinjaFact()
                if let fact = ninjaFacts.first {
                    // Check if it contains science keywords
                    let scienceKeywords = [
                        "science", "physics", "chemistry", "biology", "space", "planet", "atom", "research",
                        "scientist", "laboratory", "experiment", "theory", "hypothesis", "discovery",
                        "invention", "technology", "innovation", "engineering", "quantum", "molecular",
                        "cell", "DNA", "RNA", "gene", "genome", "protein", "enzyme", "bacteria", "virus",
                        "solar", "lunar", "stellar", "cosmic", "galaxy", "universe", "astronomy", "telescope",
                        "microscope", "element", "compound", "reaction", "molecule", "particle", "electron",
                        "proton", "neutron", "isotope", "radiation", "energy", "force", "gravity", "magnetic",
                        "electric", "current", "voltage", "frequency", "wavelength", "spectrum"
                    ]
                    
                    let isScienceFact = scienceKeywords.contains { keyword in
                        fact.text.lowercased().contains(keyword.lowercased())
                    }
                    
                    if isScienceFact {
                        return Fact(text: fact.text, category: "Science", isFavorite: false)
                    }
                }
            }
            
            // If still no match, return a random fact with Science category
            let randomFact = try await fetchRandomFact()
            return Fact(text: randomFact.text, category: "Science", isFavorite: false)
            
        default:
            return try await fetchRandomFact()
        }
    }
    
    // MARK: - Helper Methods
    
    // Add a fact to the recent facts cache
    private func addToRecentFacts(_ factText: String) {
        // Add to the beginning of the array
        recentFacts.insert(factText, at: 0)
        
        // Keep the cache size under control
        if recentFacts.count > maxCacheSize {
            recentFacts.removeLast()
        }
    }
    
    // Check if a fact is in the recent facts cache
    private func isRecentFact(_ factText: String) -> Bool {
        return recentFacts.contains(factText)
    }
} 