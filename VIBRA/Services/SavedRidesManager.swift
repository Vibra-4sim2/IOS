//
//  SavedRidesManager.swift
//  VIBRA
//
//  Manager for saving rides locally for offline access
//

import Foundation

final class SavedRidesManager {
    static let shared = SavedRidesManager()
    
    private let savedRidesKey = "savedRides_v2"
    private let savedCreatorsKey = "savedCreators_v2"
    
    private init() {}
    
    // MARK: - Save Ride
    
    func saveRide(_ ride: Ride, creator: User?) {
        var savedRides = getSavedRides()
        
        // Check if already saved
        if savedRides.contains(where: { $0.id == ride.id }) {
            print("⚠️ Ride already saved: \(ride.titre)")
            return // Already saved
        }
        
        savedRides.append(ride)
        
        // Save to UserDefaults
        do {
            let encoded = try JSONEncoder().encode(savedRides)
            UserDefaults.standard.set(encoded, forKey: savedRidesKey)
            UserDefaults.standard.synchronize()
            print("✅ Ride saved: \(ride.titre) - Total saved: \(savedRides.count)")
        } catch {
            print("❌ Error encoding rides: \(error)")
        }
        
        // Save creator separately
        if let creator = creator {
            saveCreator(creator, forRideId: ride.id ?? "")
        }
    }
    
    // MARK: - Remove Saved Ride
    
    func removeSavedRide(_ rideId: String) {
        var savedRides = getSavedRides()
        let countBefore = savedRides.count
        savedRides.removeAll { $0.id == rideId }
        
        do {
            let encoded = try JSONEncoder().encode(savedRides)
            UserDefaults.standard.set(encoded, forKey: savedRidesKey)
            UserDefaults.standard.synchronize()
            print("🗑️ Ride removed: \(rideId) - Was: \(countBefore), Now: \(savedRides.count)")
        } catch {
            print("❌ Error encoding rides after removal: \(error)")
        }
        
        // Remove associated creator
        removeCreator(forRideId: rideId)
    }
    
    // MARK: - Check if Ride is Saved
    
    func isRideSaved(_ rideId: String?) -> Bool {
        guard let rideId = rideId else { return false }
        let isSaved = getSavedRides().contains { $0.id == rideId }
        return isSaved
    }
    
    // MARK: - Get All Saved Rides
    
    func getSavedRides() -> [Ride] {
        guard let data = UserDefaults.standard.data(forKey: savedRidesKey) else {
            print("📭 No saved rides data found")
            return []
        }
        
        do {
            let rides = try JSONDecoder().decode([Ride].self, from: data)
            print("📬 Loaded \(rides.count) saved rides")
            return rides
        } catch {
            print("❌ Error decoding saved rides: \(error)")
            return []
        }
    }
    
    // MARK: - Get Saved Rides with Creators
    
    func getSavedRidesWithCreators() -> [RideWithCreator] {
        let rides = getSavedRides()
        print("🔄 Getting \(rides.count) saved rides with creators")
        return rides.map { ride in
            let creator = getCreator(forRideId: ride.id ?? "")
            return RideWithCreator(ride: ride, creator: creator)
        }
    }
    
    // MARK: - Creator Management
    
    private func saveCreator(_ creator: User, forRideId rideId: String) {
        var creators = getAllCreators()
        creators[rideId] = creator
        
        do {
            let encoded = try JSONEncoder().encode(creators)
            UserDefaults.standard.set(encoded, forKey: savedCreatorsKey)
            UserDefaults.standard.synchronize()
            print("✅ Creator saved for ride: \(rideId)")
        } catch {
            print("❌ Error saving creator: \(error)")
        }
    }
    
    private func getCreator(forRideId rideId: String) -> User? {
        let creators = getAllCreators()
        return creators[rideId]
    }
    
    private func removeCreator(forRideId rideId: String) {
        var creators = getAllCreators()
        creators.removeValue(forKey: rideId)
        
        do {
            let encoded = try JSONEncoder().encode(creators)
            UserDefaults.standard.set(encoded, forKey: savedCreatorsKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ Error removing creator: \(error)")
        }
    }
    
    private func getAllCreators() -> [String: User] {
        guard let data = UserDefaults.standard.data(forKey: savedCreatorsKey) else {
            return [:]
        }
        
        do {
            let creators = try JSONDecoder().decode([String: User].self, from: data)
            return creators
        } catch {
            print("❌ Error decoding creators: \(error)")
            return [:]
        }
    }
    
    // MARK: - Clear All Saved
    
    func clearAllSaved() {
        UserDefaults.standard.removeObject(forKey: savedRidesKey)
        UserDefaults.standard.removeObject(forKey: savedCreatorsKey)
        UserDefaults.standard.synchronize()
        print("🗑️ All saved rides cleared")
    }
    
    // MARK: - Count
    
    var savedCount: Int {
        getSavedRides().count
    }
}
