import Foundation

class BarcodeService: ObservableObject {
    static let shared = BarcodeService()
    
    private init() {}
    
    func lookupBarcode(_ barcode: String) async throws -> FoodItem? {
        // TODO: Implement barcode lookup using OpenFoodFacts API
        // For now, return mock data for common barcodes
        
        let mockDatabase: [String: (name: String, protein: Double, brand: String)] = [
            "4002971113013": ("Protein Shake Vanille", 80.0, "Weider"),
            "4260275024081": ("Griechischer Joghurt", 9.0, "Fage"),
            "8712000002021": ("Thunfisch in Wasser", 25.0, "John West"),
            "4311501374238": ("Hüttenkäse", 13.0, "Milbona"),
            "7622210991072": ("Protein Riegel", 20.0, "Quest")
        ]
        
        if let mockData = mockDatabase[barcode] {
            return FoodItem(
                name: mockData.name,
                proteinPer100g: mockData.protein,
                source: .api,
                barcode: barcode,
                brand: mockData.brand
            )
        }
        
        // If not in mock database, try OpenFoodFacts API
        return try await fetchFromOpenFoodFacts(barcode)
    }
    
    private func fetchFromOpenFoodFacts(_ barcode: String) async throws -> FoodItem? {
        let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let openFoodFactsResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            
            guard openFoodFactsResponse.status == 1,
                  let product = openFoodFactsResponse.product else {
                return nil
            }
            
            let proteinPer100g = Double(product.nutriments.proteins_100g ?? "0") ?? 0
            
            return FoodItem(
                name: product.productName ?? "Unbekanntes Produkt",
                proteinPer100g: proteinPer100g,
                source: .api,
                barcode: barcode,
                brand: product.brands
            )
            
        } catch {
            print("Error fetching from OpenFoodFacts: \(error)")
            return nil
        }
    }
}

// MARK: - OpenFoodFacts API Models

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let nutriments: OpenFoodFactsNutriments
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case nutriments
    }
}

struct OpenFoodFactsNutriments: Codable {
    let proteins_100g: String?
    let energy_100g: String?
    let fat_100g: String?
    let carbohydrates_100g: String?
}