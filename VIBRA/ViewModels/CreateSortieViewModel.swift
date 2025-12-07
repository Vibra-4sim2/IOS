//
//  CreateSortieViewModel.swift
//  VIBRA
//

import Foundation
import CoreLocation
import MapKit
import Combine
import SwiftUI
import PhotosUI

@MainActor
final class CreateSortieViewModel: ObservableObject {
    
    // MARK: - Champs Sortie
    
    @Published var type: String = "RANDO"
    @Published var titre: String = ""
    @Published var description: String = ""
    @Published var date: Date = Date()
    @Published var optionCamping: Bool = false
    
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var selectedUIImage: UIImage? = nil
    @Published var photoData: Data? = nil
    @Published var isLoadingImage: Bool = false
    
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
    
    // Nouveaux champs pour l'autocomplétion
    @Published var departSearchResults: [MKMapItem] = []
    @Published var arriveeSearchResults: [MKMapItem] = []
    @Published var isSearchingDepart: Bool = false
    @Published var isSearchingArrivee: Bool = false
    
    @Published var isFetchingRoute: Bool = false
    
    // Position utilisateur
    @Published var userLocation: CLLocationCoordinate2D? = nil
    
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
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    init(service: SortieService = .shared) {
        self.service = service
        
        // Charger l'image quand selectedPhotoItem change
        $selectedPhotoItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { await self?.loadImage(from: item) }
            }
            .store(in: &cancellables)
        
        // Recherche d'adresses pour le départ
        $departAddressText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchAddress(query: query, forDeparture: true)
                } else {
                    self?.departSearchResults = []
                }
            }
            .store(in: &cancellables)
        
        // Recherche d'adresses pour l'arrivée
        $arriveeAddressText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchAddress(query: query, forDeparture: false)
                } else {
                    self?.arriveeSearchResults = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Gestion image
    
    private func loadImage(from item: PhotosPickerItem) async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    self.photoData = data
                    self.selectedUIImage = UIImage(data: data)
                }
            } else {
                await MainActor.run {
                    self.photoData = nil
                    self.selectedUIImage = nil
                }
            }
        } catch {
            await MainActor.run {
                self.photoData = nil
                self.selectedUIImage = nil
                self.showValidationError("Impossible de charger l'image sélectionnée.")
            }
        }
    }
    
    // MARK: - Géolocalisation
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func updateUserLocation(_ location: CLLocationCoordinate2D) {
        userLocation = location
    }
    
    // MARK: - Recherche d'adresses
    
    func searchAddress(query: String, forDeparture: Bool) {
        if forDeparture {
            isSearchingDepart = true
        } else {
            isSearchingArrivee = true
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Utiliser la position de l'utilisateur comme région de recherche si disponible
        if let userLoc = userLocation {
            request.region = MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if forDeparture {
                    self.isSearchingDepart = false
                    if let response = response {
                        self.departSearchResults = response.mapItems
                    }
                } else {
                    self.isSearchingArrivee = false
                    if let response = response {
                        self.arriveeSearchResults = response.mapItems
                    }
                }
            }
        }
    }
    
    func selectDepartureAddress(_ mapItem: MKMapItem) {
        startCoordinate = mapItem.placemark.coordinate
        departAddressText = mapItem.name ?? mapItem.placemark.title ?? ""
        departSearchResults = []
        
        // Géocodage inverse pour obtenir l'adresse complète
        reverseGeocode(coordinate: mapItem.placemark.coordinate) { [weak self] address in
            if let address = address {
                self?.departAddressText = address
            }
        }
    }
    
    func selectArrivalAddress(_ mapItem: MKMapItem) {
        endCoordinate = mapItem.placemark.coordinate
        arriveeAddressText = mapItem.name ?? mapItem.placemark.title ?? ""
        arriveeSearchResults = []
        
        // Géocodage inverse pour obtenir l'adresse complète
        reverseGeocode(coordinate: mapItem.placemark.coordinate) { [weak self] address in
            if let address = address {
                self?.arriveeAddressText = address
            }
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil)
                return
            }
            
            var addressParts: [String] = []
            
            if let name = placemark.name {
                addressParts.append(name)
            }
            if let locality = placemark.locality {
                addressParts.append(locality)
            }
            if let country = placemark.country {
                addressParts.append(country)
            }
            
            let address = addressParts.joined(separator: ", ")
            completion(address.isEmpty ? nil : address)
        }
    }
    
    // MARK: - Map interactions
    
    func setStartCoordinate(_ coord: CLLocationCoordinate2D) {
        startCoordinate = coord
        
        // Géocodage inverse pour mettre à jour l'adresse
        reverseGeocode(coordinate: coord) { [weak self] address in
            if let address = address {
                DispatchQueue.main.async {
                    self?.departAddressText = address
                }
            }
        }
    }
    
    func setEndCoordinate(_ coord: CLLocationCoordinate2D) {
        endCoordinate = coord
        
        // Géocodage inverse pour mettre à jour l'adresse
        reverseGeocode(coordinate: coord) { [weak self] address in
            if let address = address {
                DispatchQueue.main.async {
                    self?.arriveeAddressText = address
                }
            }
        }
    }
    
    // MARK: - Appel ORS
    
    func fetchRoute() async {
        guard let start = startCoordinate, let end = endCoordinate else {
            showValidationError("Veuillez choisir un point de départ et un point d'arrivée.")
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
            showValidationError("Erreur lors de la récupération de l'itinéraire.")
        }
        
        isFetchingRoute = false
    }
    
    // MARK: - Création Sortie + Camping + Participation auto créateur (ACCEPTEE)
    
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
                throw ValidationError("Veuillez calculer l'itinéraire avant de créer la sortie.")
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
                    throw ValidationError("Vous n'êtes pas authentifié (401) pour créer un camping.")
                }
            }
            
            // ---------- Itinéraire JSON ----------
            let itinDict = try buildItineraireJSONDict(from: itin)
            let itinData = try JSONSerialization.data(withJSONObject: itinDict, options: [])
            guard let itinJSON = String(data: itinData, encoding: .utf8) else {
                throw ValidationError("Impossible de préparer les données d'itinéraire.")
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
                typeUI: type,
                optionCamping: optionCamping,
                photoData: photoData,
                lieu: lieuSortie,
                difficulte: difficulte,
                niveau: niveau,
                capacite: capacite,
                prix: prixSortie,
                campingId: campingId,
                itineraireJSON: itinJSON,
                campingJSON: campingJSON
            )
            
            // ---------- Création de la sortie ----------
            let sortieResp = try await service.createSortieMultipart(sortiePayload)
            
            #if DEBUG
            print("[CreateSortieVM] Sortie créée: id=\(sortieResp._id)")
            #endif
            
            // ---------- Récupérer userId depuis le JWT ----------
            var currentUserId: String? = nil
            do {
                let token = try KeychainManager.shared.getJWT()
                currentUserId = token.getUserIdFromJWT()
            } catch {
                #if DEBUG
                print("[CreateSortieVM] Erreur lors de la récupération du JWT pour extraire userId:", error)
                #endif
            }
            
            // ---------- Création auto de la participation ACCEPTEE pour le créateur ----------
            if let userId = currentUserId {
                do {
                    let participation = try await ParticipationService.shared.createAcceptedParticipationForCreator(
                        userId: userId,
                        sortieId: sortieResp._id
                    )
                    
                    #if DEBUG
                    print("[CreateSortieVM] Participation auto créée: user=\(participation.user?.id ?? "?") sortie=\(participation.sortie?.id ?? "?") status=\(participation.status ?? "?")")
                    #endif
                    
                    successMessage = "Sortie créée avec succès (id: \(sortieResp._id)) et participation confirmée."
                    showSuccessAlert = true
                } catch {
                    #if DEBUG
                    print("[CreateSortieVM] Erreur création participation auto:", error)
                    #endif
                    successMessage = "Sortie créée avec succès (id: \(sortieResp._id)), mais la participation automatique n'a pas pu être créée."
                    showSuccessAlert = true
                }
            } else {
                successMessage = "Sortie créée avec succès (id: \(sortieResp._id)), mais la participation automatique n'a pas pu être créée (userId introuvable dans le JWT)."
                showSuccessAlert = true
            }
            
            // Reset du formulaire après la création
            resetForm()
            
        } catch let error as ValidationError {
            showValidationError(error.message)
        } catch SortieServiceError.unauthorized {
            showValidationError("Vous n'êtes pas authentifié (401). Connectez-vous puis réessayez.")
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
        
        selectedPhotoItem = nil
        selectedUIImage = nil
        photoData = nil
        isLoadingImage = false
        
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
        departSearchResults = []
        arriveeSearchResults = []
        
        campingNom = ""
        campingDescription = ""
        campingLieu = ""
        campingPrix = nil
        campingParticipants = nil
        campingDateDebut = Date()
        campingDateFin = Date().addingTimeInterval(86400)
    }
    
    // MARK: - Helpers erreur
    
    fileprivate func showValidationError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

struct ValidationError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
