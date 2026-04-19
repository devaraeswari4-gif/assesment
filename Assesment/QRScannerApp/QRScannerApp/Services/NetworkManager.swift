import Foundation

enum APIError: Error {
    case badURL, invalidResponse, decoding
}

struct OpenFoodResponse: Codable {
    let product: FoodProduct?
}

struct FoodProduct: Codable {
    let product_name: String?
    let categories: String?
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func fetchProduct(barcode: String) async throws -> Product {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")
        else { throw APIError.badURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OpenFoodResponse.self, from: data)

        guard let p = decoded.product else {
            return Product(name: "Unknown", category: "-", isVerified: false)
        }

        return Product(
            name: p.product_name ?? "No Name",
            category: p.categories ?? "No Category",
            isVerified: true
        )
    }
}
