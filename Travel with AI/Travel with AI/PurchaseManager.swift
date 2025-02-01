import UIKit
import StoreKit

class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()
    @Published var isSubscribed: Bool = false

    private var product: SKProduct?

    override init() {
        super.init()
        SKPaymentQueue.default().add(self) // Add observer to the payment queue
    }

    deinit {
        SKPaymentQueue.default().remove(self) // Remove observer to prevent memory leaks
    }

    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: ["TravelWithAIMonthlyAccess"])
        request.delegate = self
        request.start()
    }

    func purchaseSubscription() {
        guard let product = product else {
            showError(message: "Product not found.")
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func checkSubscriptionStatus() {
        // Add receipt validation here or mock subscription status for now
        isSubscribed = true // Mock status for demonstration
    }

    private func showError(message: String) {
        // Ensure that the alert is presented on the main thread
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.isEmpty {
            showError(message: "No products found.")
        } else {
            if let fetchedProduct = response.products.first {
                self.product = fetchedProduct
            }
        }
    }
}

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                isSubscribed = true
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let error = transaction.error as? SKError {
                    showError(message: error.localizedDescription)
                } else {
                    showError(message: "Transaction failed.")
                }
            default:
                break
            }
        }
    }
}
