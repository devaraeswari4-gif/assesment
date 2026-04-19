import Foundation

@MainActor
final class ProductViewModel {
    private(set) var product: Product?

    func load(qr: String) async throws {
        product = try await NetworkManager.shared.fetchProduct(barcode: qr)
    }
}
