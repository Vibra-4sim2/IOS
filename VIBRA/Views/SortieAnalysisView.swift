//
//  SortieAnalysisView.swift
//  VIBRA
//
//  Vue pour afficher l'analyse IA d'une sortie
//

import SwiftUI

struct SortieAnalysisView: View {
    @StateObject private var vm: SortieAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(sortieId: String, sortieTitle: String) {
        _vm = StateObject(wrappedValue: SortieAnalysisViewModel(sortieId: sortieId, sortieTitle: sortieTitle))
    }
    
    var body: some View {
        ZStack {
            // Fond gradient
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if vm.isLoading {
                    LoadingSkeletonView()
                        .padding(.horizontal)
                        .transition(.opacity)
                } else if let error = vm.errorMessage {
                    ErrorView(message: error) {
                        Task { await vm.loadAnalysis() }
                    }
                    .padding(.horizontal)
                } else if vm.analysisResponse != nil {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            HeaderCard
                                .padding(.horizontal)
                            
                            if let analysis = vm.analysis {
                                AnalysisCard(analysis: analysis)
                                    .padding(.horizontal)
                            }
                            
                            if !vm.personalizedTips.isEmpty {
                                TipsCard(
                                    title: "💡 Conseils Personnalisés",
                                    tips: vm.personalizedTips,
                                    color: AppColors.GreenAccent
                                )
                                .padding(.horizontal)
                            }
                            
                            if !vm.safetyWarnings.isEmpty {
                                TipsCard(
                                    title: "⚠️ Avertissements de Sécurité",
                                    tips: vm.safetyWarnings,
                                    color: AppColors.ErrorRed
                                )
                                .padding(.horizontal)
                            }
                            
                            if !vm.preparationChecklist.isEmpty {
                                TipsCard(
                                    title: "✅ Checklist de Préparation",
                                    tips: vm.preparationChecklist,
                                    color: AppColors.TealAccent
                                )
                                .padding(.horizontal)
                            }
                            
                            if !vm.nutritionTips.isEmpty {
                                TipsCard(
                                    title: "🍎 Conseils Nutrition",
                                    tips: vm.nutritionTips,
                                    color: AppColors.AmberAccent
                                )
                                .padding(.horizontal)
                            }
                            
                            if !vm.allEquipment.isEmpty {
                                EquipmentSection
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                    .transition(.opacity)
                } else {
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            await vm.loadAnalysis()
        }
    }
    
    // MARK: - Navigation Bar
    private var NavigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(AppColors.CardGlass)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.DividerColor, lineWidth: 0.8))
                    .shadow(color: AppColors.ShadowColor, radius: 6, x: 0, y: 3)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Analyse IA")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)
                
                if vm.isPersonalized {
                    Text("Personnalisée")
                        .font(.caption2)
                        .foregroundColor(AppColors.GreenAccent)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(Color.clear)
                .frame(width: 38, height: 38)
        }
    }
    
    // MARK: - Header Card
    private var HeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.GreenAccent.opacity(0.12))
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.GreenAccent)
                }
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.sortieTitle)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    
                    if let userLevel = vm.userLevel {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(AppColors.TextSecondary)
                            Text("Niveau: \(userLevel.capitalized)")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
                .shadow(color: AppColors.ShadowColor.opacity(0.35), radius: 10, x: 0, y: 8)
        )
    }
    
    // MARK: - Equipment Section
    private var EquipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.GreenAccent.opacity(0.12))
                    Image(systemName: "backpack.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.GreenAccent)
                }
                .frame(width: 34, height: 34)
                
                Text("Équipements Recommandés")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)
                
                Spacer()
            }
            
            // Summary
            if let summary = vm.equipmentSummary {
                EquipmentSummaryView(summary: summary)
            }
            
            Divider()
                .overlay(AppColors.BorderColor)
                .padding(.vertical, 4)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(
                        title: "Tous (\(vm.allEquipment.count))",
                        isSelected: vm.selectedNecessity == nil
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.resetFilter()
                        }
                    }
                    
                    FilterChip(
                        title: "🔴 Essentiels (\(vm.essentialCount))",
                        isSelected: vm.selectedNecessity == .essential
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.filterEquipment(by: .essential)
                        }
                    }
                    
                    FilterChip(
                        title: "🟡 Recommandés (\(vm.recommendedCount))",
                        isSelected: vm.selectedNecessity == .recommended
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.filterEquipment(by: .recommended)
                        }
                    }
                    
                    FilterChip(
                        title: "🟢 Optionnels (\(vm.optionalCount))",
                        isSelected: vm.selectedNecessity == .optional
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.filterEquipment(by: .optional)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // Equipment Grid
            AdaptiveEquipmentGrid(items: vm.filteredEquipment)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
                .shadow(color: AppColors.ShadowColor.opacity(0.35), radius: 10, x: 0, y: 8)
        )
    }
}

// MARK: - Adaptive Equipment Grid
private struct AdaptiveEquipmentGrid: View {
    let items: [Equipment]
    private var columns: [GridItem] {
        // Deux colonnes sur iPhone en portrait, 3 sur grands écrans
        [GridItem(.adaptive(minimum: 160), spacing: 14)]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { equipment in
                EquipmentCard(equipment: equipment)
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: items.count)
            }
        }
    }
}

// MARK: - Analysis Card
struct AnalysisCard: View {
    let analysis: DifficultyAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.GreenAccent.opacity(0.12))
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.GreenAccent)
                }
                .frame(width: 34, height: 34)
                
                Text("Analyse de Difficulté")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.TextPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let score = analysis.difficultyScore {
                    AnalysisChip(
                        icon: "gauge.high",
                        label: "Score",
                        value: "\(score)/10",
                        color: colorForScore(score)
                    )
                }
                
                if let label = analysis.difficultyLabel {
                    AnalysisChip(
                        icon: "flag.fill",
                        label: "Niveau",
                        value: label,
                        color: AppColors.TealAccent
                    )
                }
                
                if let duration = analysis.estimatedDuration {
                    AnalysisChip(
                        icon: "clock.fill",
                        label: "Durée",
                        value: duration,
                        color: AppColors.AmberAccent
                    )
                }
                
                if let physical = analysis.physicalDemand {
                    AnalysisChip(
                        icon: "figure.walk",
                        label: "Physique",
                        value: physical,
                        color: AppColors.GreenAccent
                    )
                }
                
                if let technical = analysis.technicalDemand {
                    AnalysisChip(
                        icon: "gear",
                        label: "Technique",
                        value: technical,
                        color: AppColors.InfoBlue
                    )
                }
                
                if let season = analysis.bestSeason {
                    AnalysisChip(
                        icon: "sun.max.fill",
                        label: "Saison",
                        value: season,
                        color: AppColors.WarningOrange
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
                .shadow(color: AppColors.ShadowColor.opacity(0.35), radius: 10, x: 0, y: 8)
        )
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 0...3: return AppColors.SuccessGreen
        case 4...6: return AppColors.WarningOrange
        default: return AppColors.ErrorRed
        }
    }
}

// MARK: - Analysis Chip
struct AnalysisChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.TextSecondary)
            
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.TextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.CardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tips Card
struct TipsCard: View {
    let title: String
    let tips: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.TextPrimary)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(tip)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.TextPrimary.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.CardGlass)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(color.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.CardDark.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.BorderColor, lineWidth: 0.7)
                )
                .shadow(color: AppColors.ShadowColor.opacity(0.35), radius: 10, x: 0, y: 8)
        )
    }
}

// MARK: - Equipment Summary View
struct EquipmentSummaryView: View {
    let summary: EquipmentSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let essential = summary.essentialCount {
                    SummaryBadge(count: essential, label: "Essentiels", color: AppColors.ErrorRed)
                }
                if let recommended = summary.recommendedCount {
                    SummaryBadge(count: recommended, label: "Recommandés", color: AppColors.WarningOrange)
                }
                if let optional = summary.optionalCount {
                    SummaryBadge(count: optional, label: "Optionnels", color: AppColors.SuccessGreen)
                }
                Spacer()
            }
            
            if let cost = summary.totalEstimatedCost {
                Text("💰 Budget estimé: \(cost)")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
        }
    }
}

struct SummaryBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppColors.TextSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : AppColors.TextPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AppColors.GreenAccent : AppColors.CardGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? AppColors.GreenAccent : AppColors.BorderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Equipment Card
struct EquipmentCard: View {
    let equipment: Equipment
    
    var body: some View {
        VStack(spacing: 10) {
            // Image (uniformisée)
            EquipmentImage(urlString: equipment.image)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(equipment.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.TextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    Spacer()
                    
                    NecessityBadge(level: equipment.necessityLevel)
                }
                
                if !equipment.description.isEmpty {
                    Text(equipment.description)
                        .font(.caption2)
                        .foregroundColor(AppColors.TextSecondary)
                        .lineLimit(3)
                }
                
                if let price = equipment.priceRange {
                    Text(price)
                        .font(.caption)
                        .foregroundColor(AppColors.GreenAccent)
                        .fontWeight(.semibold)
                }
                
                if let reason = equipment.necessityReason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(AppColors.InfoBlue)
                        .italic()
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                if let buyLink = equipment.buyLink, let url = URL(string: buyLink) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.fill")
                            Text("Acheter")
                                .lineLimit(1)
                        }
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(AppColors.GreenAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        // Hauteur minimale pour uniformiser les cartes dans la grille
        .frame(minHeight: 270)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.CardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.BorderColor, lineWidth: 0.6)
                )
                .shadow(color: AppColors.ShadowColor.opacity(0.25), radius: 6, x: 0, y: 4)
        )
    }
}

// Image helper pour uniformiser les ratios et placeholders
private struct EquipmentImage: View {
    let urlString: String?
    
    var body: some View {
        Group {
            if let imageUrl = urlString, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.CardGlass)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.GreenAccent))
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.CardGlass)
                            Image(systemName: "photo")
                                .foregroundColor(AppColors.TextTertiary)
                        }
                    @unknown default:
                        Color.clear
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.CardGlass)
                    Image(systemName: "backpack.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.TextTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4/3, contentMode: .fit) // ratio fixe pour des cartes ordonnées
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.BorderColor, lineWidth: 0.5)
        )
    }
}

// MARK: - Necessity Badge
struct NecessityBadge: View {
    let level: NecessityLevel
    
    var color: Color {
        switch level {
        case .essential: return AppColors.ErrorRed
        case .recommended: return AppColors.WarningOrange
        case .optional: return AppColors.SuccessGreen
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
            Text(level.displayName)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Loading View (squelette)
struct LoadingSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            skeletonCard(height: 90)
            skeletonCard(height: 160)
            skeletonCard(height: 280)
            skeletonCard(height: 280)
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }
    
    private func skeletonCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(AppColors.CardDark.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.BorderColor, lineWidth: 0.7)
            )
            .frame(height: height)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.ErrorRed)
            
            Text("Erreur")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.TextPrimary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: retry) {
                Text("Réessayer")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(AppColors.GreenAccent)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SortieAnalysisView(
            sortieId: "692b9edf090ea1b72ad690e4",
            sortieTitle: "Test Python Sortie"
        )
    }
}

// MARK: - Helpers: Shimmer (optionnel)
extension View {
    func shimmer() -> some View {
        self
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(8))
                .mask(self)
                .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: UUID())
            )
    }
}
