//
//  RideLocationManager.swift
//  VIBRA
//

import Foundation
import CoreLocation
import Combine

@MainActor
class RideLocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocation() {
        print("📍 RideLocationManager: Requesting location...")
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 RideLocationManager: Authorization not determined, requesting...")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 RideLocationManager: Already authorized, starting updates...")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("⚠️ RideLocationManager: Location access denied or restricted")
            errorMessage = "Accès à la localisation refusé. Activez-le dans les réglages."
        @unknown default:
            break
        }
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000
    }
}

extension RideLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            print("✅ RideLocationManager: Location updated - \(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.location = location
            self.errorMessage = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ RideLocationManager: Failed with error - \(error.localizedDescription)")
            self.errorMessage = "Erreur de localisation: \(error.localizedDescription)"
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            print("📍 RideLocationManager: Authorization changed to \(status.rawValue)")
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.errorMessage = "Accès à la localisation refusé"
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
