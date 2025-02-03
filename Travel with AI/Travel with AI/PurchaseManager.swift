import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    @Published var isSubscribed: Bool = false

    var product: Product?
    private let productID = "TravelWithAIMonthlyAccess"

    init() {
        Task {
            await fetchProducts()
            await checkSubscriptionStatus()
        }
    }

    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            if let fetchedProduct = products.first {
                self.product = fetchedProduct
                print("Product fetched: \(fetchedProduct.displayName)")
            } else {
                showError(message: "No products found.")
            }
        } catch {
            showError(message: "Failed to fetch products: \(error.localizedDescription)")
        }
    }

    func purchaseSubscription() async {
        guard let product = product else {
            showError(message: "Product not found.")
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await updateSubscriptionStatus()
                    await transaction.finish()
                case .unverified(_, let error):
                    showError(message: "Purchase verification failed: \(error.localizedDescription)")
                }
            case .userCancelled:
                print("User cancelled the purchase.")
            case .pending:
                showError(message: "Purchase is pending approval.")
            @unknown default:
                showError(message: "Unknown purchase result.")
            }
        } catch {
            showError(message: "Purchase failed: \(error.localizedDescription)")
        }
    }

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                isSubscribed = true
                return
            }
        }
        isSubscribed = false
    }

    private func updateSubscriptionStatus() async {
        await checkSubscriptionStatus()
    }

    private func showError(message: String) {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = scene.windows.first?.rootViewController {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
}
