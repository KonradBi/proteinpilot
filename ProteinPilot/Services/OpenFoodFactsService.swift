import Foundation

// MARK: - OpenFoodFacts API Models
struct OFFApiResponse: Codable {
    let code: String
    let status: Int
    let product: OFFProduct?
}

struct OFFProduct: Codable {
    let productName: String?
    let brands: String?
    let nutriments: OFFNutriments?
    let imageFrontUrl: String?
    let categories: String?
    let servingSize: String?
    
    private enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case nutriments
        case imageFrontUrl = "image_front_url"
        case categories
        case servingSize = "serving_size"
    }
}

struct OFFNutriments: Codable {
    let proteins: Double?
    let proteinsValue: Double?
    let proteins100g: Double?
    let energy: Double?
    let energyKcal: Double?
    let fat: Double?
    let carbohydrates: Double?
    
    private enum CodingKeys: String, CodingKey {
        case proteins
        case proteinsValue = "proteins_value"
        case proteins100g = "proteins_100g"
        case energy
        case energyKcal = "energy-kcal"
        case fat
        case carbohydrates
    }
    
    var proteinPer100g: Double {
        return proteins100g ?? proteinsValue ?? proteins ?? 0.0
    }
}

// MARK: - Our Models
struct ScannedProduct {
    let barcode: String
    let name: String
    let brand: String?
    let proteinPer100g: Double
    let servingSize: Double
    let imageURL: String?
    let categories: String?
    
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    var proteinPerServing: Double {
        return (proteinPer100g * servingSize) / 100.0
    }
    
    var suggestedEmoji: String {
        let cats = categories?.lowercased() ?? ""
        
        if cats.contains("milk") || cats.contains("dairy") || cats.contains("yogurt") {
            return "🥛"
        } else if cats.contains("meat") || cats.contains("chicken") || cats.contains("beef") {
            return "🍖"
        } else if cats.contains("fish") || cats.contains("tuna") || cats.contains("salmon") {
            return "🐟"
        } else if cats.contains("protein") || cats.contains("supplement") {
            return "💪"
        } else if cats.contains("cheese") {
            return "🧀"
        } else if cats.contains("egg") {
            return "🥚"
        } else {
            return "🏷️"
        }
    }
    
    func toFoodItem() -> FoodItem {
        return FoodItem(
            name: displayName,
            emoji: suggestedEmoji,
            proteinPer100g: proteinPer100g,
            defaultPortionGrams: servingSize,
            source: .api
        )
    }
}

// MARK: - Service
@MainActor
class OpenFoodFactsService: ObservableObject {
    static let shared = OpenFoodFactsService()
    
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session = URLSession.shared
    
    private init() {}
    
    func lookupProduct(barcode: String) async throws -> ScannedProduct? {
        let url = URL(string: "\(baseURL)/\(barcode)")!
        
        print("🔍 Looking up barcode: \(barcode)")
        print("📡 Full URL: \(url.absoluteString)")
        
        let (data, httpResponse) = try await session.data(from: url)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        guard response.statusCode == 200 else {
            throw OpenFoodFactsError.httpError(response.statusCode)
        }
        
        let apiResponse = try JSONDecoder().decode(OFFApiResponse.self, from: data)
        
        guard apiResponse.status == 1, let product = apiResponse.product else {
            return nil
        }
        
        return ScannedProduct(
            barcode: barcode,
            name: cleanProductName(product.productName),
            brand: product.brands,
            proteinPer100g: product.nutriments?.proteinPer100g ?? 0.0,
            servingSize: extractServingSize(product.servingSize),
            imageURL: product.imageFrontUrl,
            categories: product.categories
        )
    }
    
    private func cleanProductName(_ name: String?) -> String {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return "Unbekanntes Produkt"
        }
        
        var cleaned = name
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleaned.isEmpty {
            cleaned = String(cleaned.prefix(1)).uppercased() + String(cleaned.dropFirst())
        }
        
        return cleaned.isEmpty ? "Unbekanntes Produkt" : cleaned
    }
    
    private func extractServingSize(_ servingString: String?) -> Double {
        guard let serving = servingString else { return 100.0 }
        
        let numbers = serving.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let size = Double(numbers), size > 0 {
            return size
        }
        
        return 100.0
    }
}

enum OpenFoodFactsError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case noProductFound
    case invalidBarcode
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .httpError(let code):
            return "Server-Fehler: \(code)"
        case .noProductFound:
            return "Produkt nicht in der Datenbank gefunden"
        case .invalidBarcode:
            return "Ungültiger Barcode"
        }
    }
}

#if DEBUG
extension ScannedProduct {
    static let sampleThunfisch = ScannedProduct(
        barcode: "20143324",
        name: "Thunfisch in eigenem Saft",
        brand: "Seitenbacher",
        proteinPer100g: 25.0,
        servingSize: 150,
        imageURL: nil,
        categories: "fish,canned-fish,tuna"
    )
    
    static let sampleQuark = ScannedProduct(
        barcode: "4337185396007",
        name: "Skyr Natur",
        brand: "Arla",
        proteinPer100g: 11.0,
        servingSize: 150,
        imageURL: nil,
        categories: "dairy,fermented-dairy-products,yogurt"
    )
}
#endif