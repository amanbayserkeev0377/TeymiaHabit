import SwiftUI
import RevenueCat

@Observable @MainActor
class ProManager {
    static let shared = ProManager()
    
    private(set) var isPro: Bool = false
    private(set) var offerings: Offerings?
    private(set) var isLoading: Bool = false
    private(set) var hasLifetimePurchase: Bool = false
    private(set) var hasActiveSubscription: Bool = false
    
    private init() {
        #if DEBUG
        isPro = true
        hasLifetimePurchase = true
        #endif
        
        checkProStatus()
        loadOfferings()
    }
    
    // MARK: - Debug Methods
    #if DEBUG
    @MainActor
    func resetProStatusForTesting() {
        let previousProStatus = isPro
        
        isPro = false
        hasLifetimePurchase = false
        hasActiveSubscription = false
        
        if previousProStatus != isPro {
            NotificationCenter.default.post(name: .proStatusChanged, object: nil)
        }
    }
    
    @MainActor
    func setProStatusForTesting(_ status: Bool) {
        let previousProStatus = isPro
        isPro = status
        
        if previousProStatus != isPro {
            NotificationCenter.default.post(name: .proStatusChanged, object: nil)
        }
    }
    
    func toggleProStatusForTesting() {
        Task { @MainActor in
            let previousProStatus = isPro
            isPro.toggle()
            
            if previousProStatus != isPro {
                NotificationCenter.default.post(name: .proStatusChanged, object: nil)
            }
        }
    }
    #endif
    
    // MARK: - Pro Status
    func checkProStatus() {
        #if DEBUG
        return
        #else
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                await updateProStatusFromCustomerInfo(customerInfo)
                
                await MainActor.run {
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.isPro = false
                    self.hasActiveSubscription = false
                    self.hasLifetimePurchase = false
                    self.isLoading = false
                }
            }
        }
        #endif
    }
    
    // MARK: - Offerings
    func loadOfferings() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let offerings = try await withTimeout(seconds: 8) {
                    try await Purchases.shared.offerings()
                }
                
                await MainActor.run {
                    self.offerings = offerings
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.offerings = nil
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Purchase
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            await updateProStatusFromCustomerInfo(result.customerInfo)
            return isPro
        } catch {
            return false
        }
    }
    
    func purchaseLifetime() async -> Bool {
        guard let offerings = offerings,
              let lifetimePackage = findLifetimePackage(in: offerings) else {
            return false
        }
        
        return await purchase(package: lifetimePackage)
    }
    
    // MARK: - Restore
    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateProStatusFromCustomerInfo(customerInfo)
            return isPro
        } catch {
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func updateProStatusFromCustomerInfo(_ customerInfo: CustomerInfo) async {
        #if DEBUG
        return
        #else
        let hasActiveEntitlement = customerInfo.entitlements[RevenueCatConfig.Entitlements.pro]?.isActive == true
        
        let hasLifetime = customerInfo.nonSubscriptions.contains { nonSub in
            nonSub.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }
        
        let hasPro = hasActiveEntitlement || hasLifetime
        
        await MainActor.run {
            let previousProStatus = self.isPro
            
            self.isPro = hasPro
            self.hasActiveSubscription = hasActiveEntitlement
            self.hasLifetimePurchase = hasLifetime
            
            if previousProStatus != hasPro {
                NotificationCenter.default.post(name: .proStatusChanged, object: nil)
            }
        }
        #endif
    }
    
    func findLifetimePackage(in offerings: Offerings) -> Package? {
        if let lifetimePackage = offerings.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }) {
            return lifetimePackage
        }
        
        for offering in offerings.all.values {
            if let lifetimePackage = offering.availablePackages.first(where: {
                $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
            }) {
                return lifetimePackage
            }
        }
        
        return nil
    }
}

// MARK: - Pro Features
extension ProManager {
    var maxHabitsCount: Int {
        isPro ? Int.max : 3
    }
    
    var maxRemindersCount: Int {
        isPro ? 10 : 2
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let proStatusChanged = Notification.Name("proStatusChanged")
}

struct TimeoutError: Error {}
