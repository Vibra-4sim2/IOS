//
//  CreateSortieViewModel.swift
//  VIBRA
//
//  Created by mac book pro on 11/15/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class CreateSortieViewModel: ObservableObject {
    
    // MARK: - Champs Sortie
    
    @Published var titre: String = ""
    @Published var description: String = ""
    @Published var date: Date = Date()
    @Published var type: String = "RANDO"         // "RANDO" ou "VELO_ELECTRIQUE"
    @Published var optionCamping: Bool = false
    @Published var photoURL: String = ""
    @Published var capacite: Int? = nil
    
    // MARK: - Itinéraire
    
    @Published var startCoordinate: CLLocationCoordinate2D? = nil
    @Published var endCoordinate: CLLocationCoordinate2D? = nil
    @Published var itineraire: ItineraireDTO? = nil
    
    // Pour tracer la polyline
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // Adresses (info pour backend / affichage)
    @Published var departAddressText: String = ""
    @Published var arriveeAddressText: String = ""
    
    @Published var isFetchingRoute: Bool = false
    
    // MARK: - Camping
    
    @Published var campingNom: String = ""
    @Published var campingDescription: String = ""
    @Published var campingLieu: String = ""
    @Published var campingPrix: Double? = nil
    @Published var campingParticipants: Int? = nil
    @Published var campingDateDebut: Date = Date()
    @Published var campingDateFin: Date = Date().addingTimeInterval(86400)
    
    // MARK: - UI state
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    private let service: SortieService
    
    init(service: SortieService = .shared) {
        self.service = service
    }
    
    // MARK: - Map interactions
    
    func setStartCoordinate(_ coord: CLLocationCoordinate2D) {
        startCoordinate = coord
    }
    
    func setEndCoordinate(_ coord: CLLocationCoordinate2D) {
        endCoordinate = coord
    }
    
    // MARK: - Appel ORS
    
    func fetchRoute() async {
        guard let start = startCoordinate, let end = endCoordinate else {
            errorMessage = "Veuillez choisir un point de départ et un point d’arrivée."
            return
        }
        
        isFetchingRoute = true
        errorMessage = nil
        
        do {
            let itin = try await service.fetchItineraire(
                start: start,
                end: end,
                typeSortie: type,
                departName: departAddressText.isEmpty ? nil : departAddressText,
                arriveeName: arriveeAddressText.isEmpty ? nil : arriveeAddressText
            )
            
            // Garder la réponse complète
            self.itineraire = itin
            
            // Convertir la géométrie ORS → SwiftUI polyline
            if let geometry = itin.geometry {
                self.routeCoordinates = geometry.map {
                    CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                }
            } else {
                self.routeCoordinates = []
            }
            
        } catch SortieServiceError.openRouteError {
            errorMessage = "Erreur OpenRouteService (vérifie la clé API et le profil)."
        } catch SortieServiceError.decodingError {
            errorMessage = "Erreur de lecture de la réponse OpenRouteService."
        } catch {
            errorMessage = "Erreur lors de la récupération de l’itinéraire."
        }
        
        isFetchingRoute = false
    }
    
    // MARK: - Création Sortie + Camping
    
    func createSortieAndCamping() async {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        do {
            guard !titre.isEmpty else {
                throw ValidationError("Le titre de la sortie est obligatoire.")
            }
            guard itineraire != nil else {
                throw ValidationError("Veuillez calculer l’itinéraire avant de créer la sortie.")
            }
            
            var campingId: String? = nil
            
            // Camping si activé
            if optionCamping {
                guard !campingNom.isEmpty, !campingLieu.isEmpty else {
                    throw ValidationError("Veuillez remplir les informations de camping.")
                }
                
                let formatter = ISO8601DateFormatter()
                
                let campingReq = CreateCampingRequest(
                    nom: campingNom,
                    description: campingDescription.isEmpty ? nil : campingDescription,
                    lieu: campingLieu,
                    prix: campingPrix,
                    participants: campingParticipants,
                    dateDebut: formatter.string(from: campingDateDebut),
                    dateFin: formatter.string(from: campingDateFin)
                )
                
                let campingResp = try await service.createCamping(campingReq)
                campingId = campingResp._id
            }
            
            // Sortie
            let formatter = ISO8601DateFormatter()
            let sortieReq = CreateSortieRequest(
                titre: titre,
                description: description.isEmpty ? nil : description,
                date: formatter.string(from: date),
                type: type,
                option_camping: optionCamping,
                photo: photoURL.isEmpty ? nil : photoURL,
                camping: campingId,
                capacite: capacite,
                itineraire: itineraire
            )
            
            let sortieResp = try await service.createSortie(sortieReq)
            successMessage = "Sortie créée avec succès (id: \(sortieResp._id))"
            
            resetForm()
            
        } catch let error as ValidationError {
            errorMessage = error.message
        } catch {
            errorMessage = "Erreur lors de la création de la sortie."
        }
        
        isLoading = false
    }
    
    // MARK: - Reset
    
    func resetForm() {
        titre = ""
        description = ""
        date = Date()
        type = "RANDO"
        optionCamping = false
        photoURL = ""
        capacite = nil
        
        startCoordinate = nil
        endCoordinate = nil
        itineraire = nil
        routeCoordinates = []
        departAddressText = ""
        arriveeAddressText = ""
        
        campingNom = ""
        campingDescription = ""
        campingLieu = ""
        campingPrix = nil
        campingParticipants = nil
        campingDateDebut = Date()
        campingDateFin = Date().addingTimeInterval(86400)
    }
}

struct ValidationError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
