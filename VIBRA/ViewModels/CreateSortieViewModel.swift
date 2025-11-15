//
//  CreateSortieViewModel.swift
//  VIBRA
//
//  ViewModel création de sortie + camping, avec auth JWT & alertes
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
    
    @Published var difficulte: String = "MOYEN"
    @Published var niveau: String = "INTERMEDIAIRE"
    @Published var prixSortie: Double? = nil
    
    // MARK: - Itinéraire
    
    @Published var startCoordinate: CLLocationCoordinate2D? = nil
    @Published var endCoordinate: CLLocationCoordinate2D? = nil
    @Published var itineraire: ItineraireDTO? = nil
    
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
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
    @Published var showErrorAlert: Bool = false
    
    @Published var successMessage: String? = nil
    @Published var showSuccessAlert: Bool = false
    
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
            showValidationError("Veuillez choisir un point de départ et un point d’arrivée.")
            return
        }
        
        isFetchingRoute = true
        errorMessage = nil
        showErrorAlert = false
        
        do {
            let itin = try await service.fetchItineraire(
                start: start,
                end: end,
                typeSortie: type,
                departName: departAddressText.isEmpty ? nil : departAddressText,
                arriveeName: arriveeAddressText.isEmpty ? nil : arriveeAddressText
            )
            
            self.itineraire = itin
            
            if let geometry = itin.geometry {
                self.routeCoordinates = geometry.map {
                    CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                }
            } else {
                self.routeCoordinates = []
            }
            
        } catch SortieServiceError.openRouteError {
            showValidationError("Erreur OpenRouteService (vérifie la clé API et le profil).")
        } catch SortieServiceError.decodingError {
            showValidationError("Erreur de lecture de la réponse OpenRouteService.")
        } catch {
            showValidationError("Erreur lors de la récupération de l’itinéraire.")
        }
        
        isFetchingRoute = false
    }
    
    // MARK: - Création Sortie + Camping
    
    func createSortieAndCamping() async {
        errorMessage = nil
        showErrorAlert = false
        successMessage = nil
        showSuccessAlert = false
        isLoading = true
        
        #if DEBUG
        if let token = try? KeychainManager.shared.getJWT() {
            print("[CreateSortieVM] JWT from Keychain: \(token.prefix(32))...")
        } else {
            print("[CreateSortieVM] NO JWT in Keychain")
        }
        #endif
        
        do {
            guard !titre.isEmpty else {
                throw ValidationError("Le titre de la sortie est obligatoire.")
            }
            guard let itin = itineraire else {
                throw ValidationError("Veuillez calculer l’itinéraire avant de créer la sortie.")
            }
            
            let isoFormatter = ISO8601DateFormatter()
            
            // ---------- Camping ----------
            var campingId: String? = nil
            var campingJSON: String? = nil
            
            if optionCamping {
                guard !campingNom.isEmpty, !campingLieu.isEmpty else {
                    throw ValidationError("Veuillez remplir les informations de camping (nom et lieu).")
                }
                
                let campingReq = CreateCampingRequest(
                    nom: campingNom,
                    description: campingDescription.isEmpty ? nil : campingDescription,
                    lieu: campingLieu,
                    prix: campingPrix,
                    participants: campingParticipants,
                    dateDebut: isoFormatter.string(from: campingDateDebut),
                    dateFin: isoFormatter.string(from: campingDateFin)
                )
                
                do {
                    let campingResp = try await service.createCamping(campingReq)
                    campingId = campingResp._id
                    
                    var campingObj: [String: Any?] = [
                        "nom": campingResp.nom,
                        "lieu": campingResp.lieu,
                        "prix": campingResp.prix,
                        "participants": campingResp.participants,
                        "dateDebut": campingResp.dateDebut,
                        "dateFin": campingResp.dateFin,
                        "description": campingResp.description
                    ]
                    
                    campingObj = campingObj.filter { $0.value != nil }
                    
                    let data = try JSONSerialization.data(
                        withJSONObject: campingObj.compactMapValues { $0 },
                        options: []
                    )
                    campingJSON = String(data: data, encoding: .utf8)
                    
                    #if DEBUG
                    print("[CreateSortieVM] Camping JSON: \(campingJSON ?? "nil")")
                    #endif
                    
                } catch SortieServiceError.unauthorized {
                    throw ValidationError("Vous n’êtes pas authentifié (401) pour créer un camping.")
                }
            }
            
            // ---------- Itinéraire JSON ----------
            let itinDict = try buildItineraireJSONDict(from: itin)
            let itinData = try JSONSerialization.data(withJSONObject: itinDict, options: [])
            guard let itinJSON = String(data: itinData, encoding: .utf8) else {
                throw ValidationError("Impossible de préparer les données d’itinéraire.")
            }
            
            #if DEBUG
            print("[CreateSortieVM] Itineraire JSON: \(itinJSON)")
            #endif
            
            // ---------- Lieu de la sortie ----------
            let lieuSortie: String?
            if !departAddressText.isEmpty {
                lieuSortie = departAddressText
            } else if !arriveeAddressText.isEmpty {
                lieuSortie = arriveeAddressText
            } else {
                lieuSortie = nil
            }
            
            // ---------- Payload Sortie ----------
            let sortiePayload = SortieService.CreateSortieMultipartPayload(
                titre: titre,
                description: description.isEmpty ? nil : description,
                dateISO: isoFormatter.string(from: date),
                type: type,
                optionCamping: optionCamping,
                photoURL: photoURL.isEmpty ? nil : photoURL,
                lieu: lieuSortie,
                difficulte: difficulte,
                niveau: niveau,
                capacite: capacite,
                prix: prixSortie,
                campingId: campingId,
                itineraireJSON: itinJSON,
                campingJSON: campingJSON
            )
            
            let sortieResp = try await service.createSortieMultipart(sortiePayload)
            successMessage = "Sortie créée avec succès (id: \(sortieResp._id))"
            showSuccessAlert = true
            
            resetForm()
            
        } catch let error as ValidationError {
            showValidationError(error.message)
        } catch SortieServiceError.unauthorized {
            showValidationError("Vous n’êtes pas authentifié (401). Connectez-vous puis réessayez.")
        } catch SortieServiceError.invalidResponse {
            showValidationError("Réponse invalide du serveur lors de la création de la sortie.")
        } catch SortieServiceError.decodingError {
            showValidationError("Erreur de lecture de la réponse du serveur.")
        } catch {
            showValidationError("Erreur inconnue lors de la création de la sortie.")
        }
        
        isLoading = false
    }
    
    private func buildItineraireJSONDict(from itin: ItineraireDTO) throws -> [String: Any] {
        var dict: [String: Any] = [:]
        
        let depart: [String: Any] = [
            "latitude": itin.pointDepart.latitude,
            "longitude": itin.pointDepart.longitude,
            "display_name": itin.pointDepart.display_name ?? "",
            "address": itin.pointDepart.address ?? ""
        ]
        let arrivee: [String: Any] = [
            "latitude": itin.pointArrivee.latitude,
            "longitude": itin.pointArrivee.longitude,
            "display_name": itin.pointArrivee.display_name ?? "",
            "address": itin.pointArrivee.address ?? ""
        ]
        
        dict["pointDepart"] = depart
        dict["pointArrivee"] = arrivee
        dict["description"] = itin.description ?? ""
        
        if let distance = itin.distance {
            dict["distance"] = distance
        }
        if let duree = itin.duree_estimee {
            dict["duree_estimee"] = duree
        }
        if let geometry = itin.geometry {
            dict["geometry"] = geometry
        }
        if let instructions = itin.instructions {
            dict["instructions"] = instructions
        }
        
        return dict
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
        difficulte = "MOYEN"
        niveau = "INTERMEDIAIRE"
        prixSortie = nil
        
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
    
    // MARK: - Helpers erreur
    
    private func showValidationError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

struct ValidationError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
