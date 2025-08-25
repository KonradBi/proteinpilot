import Foundation

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    private let apiKey = "" // TODO: Move to secure configuration/proxy
    
    private init() {}
    
    func transcribeAudio(_ audioData: Data) async throws -> String {
        // TODO: Implement Whisper transcription
        // This would upload audio data to OpenAI Whisper API
        throw OpenAIError.notImplemented
    }
    
    func analyzeNutritionLabel(_ imageData: Data) async throws -> NutritionAnalysisResult {
        guard !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this nutrition label or food packaging image and extract the protein content. 
        Return ONLY a valid JSON response with this exact structure:
        {
            "foodName": "string",
            "proteinPer100g": number,
            "confidence": number (0-1),
            "servingSize": number,
            "servingUnit": "string",
            "brandName": "string or null"
        }
        
        If you cannot identify protein content, set confidence to 0.
        """
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 300,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.requestFailed
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        // Parse the JSON response from GPT
        guard let jsonData = content.data(using: String.Encoding.utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        return try JSONDecoder().decode(NutritionAnalysisResult.self, from: jsonData)
    }
    
    func generateFoodSuggestions(
        remainingProtein: Double,
        userPreferences: UserPreferences,
        timeOfDay: String
    ) async throws -> [FoodSuggestion] {
        guard !apiKey.isEmpty else {
            // Return mock suggestions for development
            return generateMockSuggestions(remainingProtein: remainingProtein)
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Generate 3-5 protein-rich food suggestions for someone who needs \(remainingProtein)g more protein today.
        
        User preferences:
        - Cooking skill: \(userPreferences.cookingSkill)
        - Avoid: \(userPreferences.noGos.joined(separator: ", "))
        - Time of day: \(timeOfDay)
        - Budget preference: moderate
        
        Return ONLY a valid JSON array with this structure:
        [
            {
                "foodName": "string",
                "proteinAmount": number,
                "quantity": number,
                "unit": "string",
                "prepTime": number (minutes),
                "reason": "string (why this is a good choice)",
                "difficulty": "easy|medium|hard"
            }
        ]
        
        Focus on practical, available foods that match the user's skill level and restrictions.
        """
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a nutrition assistant that provides practical food suggestions based on protein needs and user preferences. Always respond with valid JSON only."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.requestFailed
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        // Parse the JSON response from GPT
        guard let jsonData = content.data(using: String.Encoding.utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        return try JSONDecoder().decode([FoodSuggestion].self, from: jsonData)
    }
    
    func normalizeFood(_ foodDescription: String) async throws -> NormalizedFood {
        guard !apiKey.isEmpty else {
            return NormalizedFood(
                name: foodDescription,
                proteinPer100g: 20.0,
                estimatedQuantity: 100,
                confidence: 0.5
            )
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Normalize this food description and estimate protein content: "\(foodDescription)"
        
        Return ONLY valid JSON with this structure:
        {
            "name": "standardized food name",
            "proteinPer100g": number,
            "estimatedQuantity": number,
            "confidence": number (0-1)
        }
        
        Use your knowledge of nutrition facts to provide accurate protein estimates.
        """
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a nutrition database that normalizes food descriptions and provides accurate protein content estimates. Always respond with valid JSON only."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 200,
            "temperature": 0.1
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.requestFailed
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        guard let jsonData = content.data(using: String.Encoding.utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        return try JSONDecoder().decode(NormalizedFood.self, from: jsonData)
    }
    
    private func generateMockSuggestions(remainingProtein: Double) -> [FoodSuggestion] {
        let allSuggestions = [
            FoodSuggestion(
                foodName: "Griechischer Joghurt",
                proteinAmount: 20,
                quantity: 200,
                unit: "g",
                prepTime: 2,
                reason: "Reich an Protein und schnell verfügbar",
                difficulty: "easy"
            ),
            FoodSuggestion(
                foodName: "Protein Shake",
                proteinAmount: 25,
                quantity: 300,
                unit: "ml",
                prepTime: 3,
                reason: "Höchste Proteinkonzentration, perfekt für unterwegs",
                difficulty: "easy"
            ),
            FoodSuggestion(
                foodName: "Hüttenkäse mit Beeren",
                proteinAmount: 18,
                quantity: 150,
                unit: "g",
                prepTime: 3,
                reason: "Natürliches Protein mit gesunden Früchten",
                difficulty: "easy"
            ),
            FoodSuggestion(
                foodName: "Hühnerbrust gegrillt",
                proteinAmount: 35,
                quantity: 150,
                unit: "g",
                prepTime: 15,
                reason: "Mageres Protein, sehr sättigend",
                difficulty: "medium"
            ),
            FoodSuggestion(
                foodName: "Thunfischsalat",
                proteinAmount: 25,
                quantity: 100,
                unit: "g",
                prepTime: 8,
                reason: "Omega-3 Fettsäuren und hoher Proteingehalt",
                difficulty: "easy"
            )
        ]
        
        // Filter based on remaining protein and return 3-4 suggestions
        let filtered = allSuggestions.filter { $0.proteinAmount <= remainingProtein + 10 }
        return Array(filtered.prefix(4))
    }
}

// MARK: - Data Models

struct NutritionAnalysisResult: Codable {
    let foodName: String
    let proteinPer100g: Double
    let confidence: Double
    let servingSize: Double
    let servingUnit: String
    let brandName: String?
}

struct FoodSuggestion: Codable {
    let foodName: String
    let proteinAmount: Double
    let quantity: Double
    let unit: String
    let prepTime: Int
    let reason: String
    let difficulty: String
}

struct NormalizedFood: Codable {
    let name: String
    let proteinPer100g: Double
    let estimatedQuantity: Double
    let confidence: Double
}

struct UserPreferences {
    let cookingSkill: String
    let noGos: [String]
    let budget: String
    
    init(user: User) {
        self.cookingSkill = user.cookingSkills
        self.noGos = user.noGos
        self.budget = "moderate"
    }
}

// MARK: - OpenAI API Models

struct OpenAIChatResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: OpenAIChatMessage
}

struct OpenAIChatMessage: Codable {
    let content: String
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case noAPIKey
    case requestFailed
    case noContent
    case invalidResponse
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API-Schlüssel nicht konfiguriert"
        case .requestFailed:
            return "Anfrage fehlgeschlagen"
        case .noContent:
            return "Keine Antwort erhalten"
        case .invalidResponse:
            return "Ungültige Antwort"
        case .notImplemented:
            return "Funktion noch nicht implementiert"
        }
    }
}