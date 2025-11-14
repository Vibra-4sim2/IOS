//
//  MapView.swift
//  VIBRA
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Location Manager
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D? = nil
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        // Request authorization; start updating once authorized
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.location = latest.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erreur localisation : \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - MapView
struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815), // Tunis par défaut
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        ZStack(alignment: .top) {
            // Carte Apple Maps
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode
            )
            .edgesIgnoringSafeArea(.all)
            .onReceive(locationManager.$location) { location in
                guard let loc = location else { return }
                region.center = loc // mettre à jour la région dès que la position change
            }
            
            // Barre de titre + bouton recentrer
            HStack {
                Text("Carte")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    if let userLocation = locationManager.location {
                        region.center = userLocation
                        userTrackingMode = .follow
                    }
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(
                Color.black.opacity(0.3)
                    .blur(radius: 5)
                    .cornerRadius(12)
            )
            .padding(.horizontal)
            .padding(.top, 40)
        }
    }
}

// Aperçu Xcode
#Preview {
    MapView()
}

