//
//  SortieAnalysisViewModel.swift
//  VIBRA
//

import Foundation
import Combine

@MainActor
final class SortieAnalysisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisResponse: SortieAnalysisResponse?
    @Published var selectedNecessity: NecessityLevel?
    
    let sortieId: String
    let sortieTitle: String
    
    init(sortieId: String, sortieTitle: String) {
        self.sortieId = sortieId
        self.sortieTitle = sortieTitle
    }
    
    var analysis: DifficultyAnalysis? {
        analysisResponse?.analysis
    }
    
    var personalizedTips: [String] {
        analysisResponse?.personalizedTips ?? []
    }
    
    var safetyWarnings: [String] {
        analysisResponse?.safetyWarnings ?? []
    }
    
    var preparationChecklist: [String] {
        analysisResponse?.preparationChecklist ?? []
    }
    
    var nutritionTips: [String] {
        analysisResponse?.nutritionTips ?? []
    }
    
    var allEquipment: [Equipment] {
        analysisResponse?.equipment ?? []
    }
    
    var filteredEquipment: [Equipment] {
        guard let filter = selectedNecessity else {
            return allEquipment
        }
        return allEquipment.filter { $0.necessityLevel == filter }
    }
    
    var equipmentSummary: EquipmentSummary? {
        analysisResponse?.equipmentSummary
    }
    
    var isPersonalized: Bool {
        analysisResponse?.metadata?.personalized ?? false
    }
    
    var userLevel: String? {
        analysisResponse?.metadata?.userLevel
    }
    
    var essentialCount: Int {
        allEquipment.filter { $0.necessityLevel == .essential }.count
    }
    
    var recommendedCount: Int {
        allEquipment.filter { $0.necessityLevel == .recommended }.count
    }
    
    var optionalCount: Int {
        allEquipment.filter { $0.necessityLevel == .optional }.count
    }
    
    func loadAnalysis() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await SortieAnalysisService.shared.getPersonalizedAnalysis(sortieId: sortieId)
            analysisResponse = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func filterEquipment(by necessity: NecessityLevel?) {
        selectedNecessity = necessity
    }
    
    func resetFilter() {
        selectedNecessity = nil
    }
}
