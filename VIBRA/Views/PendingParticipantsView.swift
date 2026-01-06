//
//  PendingParticipantsView.swift
//  VIBRA
//
//  Vue affichant la liste des personnes qui demandent à participer à une sortie
//

import SwiftUI

struct PendingParticipantsView: View {
    let ride: Ride
    @ObservedObject var viewModel: MyRidesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var loadedUsers: [String: User] = [:]
    @State private var isLoadingUsers = true
    @State private var isProcessing = false
    
    // Get participations dynamically from viewModel
    private var participations: [Participation] {
        viewModel.pendingParticipations(for: ride.id)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Ride info card
                rideInfoCard
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Participants list
                if participations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(participations) { participation in
                                participantRow(participation)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadUserDetails()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.GreenAccent)
                    .padding(10)
                    .background(AppColors.CardGlass)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Demandes de participation")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppColors.TextPrimary)
                
                Text("\(participations.count) personne\(participations.count > 1 ? "s" : "") en attente")
                    .font(.caption)
                    .foregroundColor(AppColors.TextSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Ride Info Card
    
    private var rideInfoCard: some View {
        HStack(spacing: 12) {
            // Image de la sortie
            if let imageUrl = ride.photo, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.CardGlass)
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.CardGlass)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: ride.type == "Vélo" ? "bicycle" : "figure.hiking")
                            .font(.title2)
                            .foregroundColor(AppColors.TextSecondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(ride.titre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.TextPrimary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let activityType = ride.type {
                        Label(activityType, systemImage: activityType == "Vélo" ? "bicycle" : "figure.hiking")
                            .font(.caption2)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    
                    if ride.pointDepart != nil {
                        Label("Itinéraire défini", systemImage: "mappin")
                            .font(.caption2)
                            .foregroundColor(AppColors.TextSecondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(AppColors.CardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
    }
    
    // MARK: - Participant Row
    
    private func participantRow(_ participation: Participation) -> some View {
        let odUserId = participation.user?.id
        let user = odUserId != nil ? loadedUsers[odUserId!] : nil
        
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarUrl = user?.avatar, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(AppColors.CardGlass)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [AppColors.GreenAccent.opacity(0.3), AppColors.TealAccent.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(getInitials(from: user))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(AppColors.GreenAccent)
                        )
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    if isLoadingUsers {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                    } else if let user = user {
                        Text("\(user.firstName) \(user.lastName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextPrimary)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    } else {
                        Text(participation.user?.email ?? "Utilisateur inconnu")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.TextPrimary)
                        
                        if let odUserId = participation.user?.id {
                            Text("ID: \(odUserId.prefix(8))...")
                                .font(.caption)
                                .foregroundColor(AppColors.TextTertiary)
                        }
                    }
                    
                    // Date de la demande
                    if let createdAt = participation.createdAt {
                        Text("Demande: \(formatDate(createdAt))")
                            .font(.caption2)
                            .foregroundColor(AppColors.TextTertiary)
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Action buttons
            HStack(spacing: 12) {
                // Refuser
                Button {
                    Task {
                        if let rideId = ride.id {
                            isProcessing = true
                            await viewModel.refuseParticipation(participation, forRideId: rideId)
                            isProcessing = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                        Text("Refuser")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isProcessing)
                
                // Accepter
                Button {
                    Task {
                        if let rideId = ride.id {
                            isProcessing = true
                            await viewModel.acceptParticipation(participation, forRideId: rideId)
                            isProcessing = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                        Text("Accepter")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [AppColors.GreenAccent, AppColors.GreenDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(AppColors.CardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.BorderColor, lineWidth: 0.6)
        )
        .shadow(color: AppColors.ShadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.TextTertiary)
            
            Text("Aucune demande en attente")
                .font(.headline)
                .foregroundColor(AppColors.TextPrimary)
            
            Text("Toutes les demandes de participation ont été traitées.")
                .font(.subheadline)
                .foregroundColor(AppColors.TextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func loadUserDetails() async {
        isLoadingUsers = true
        
        for participation in participations {
            guard let userId = participation.user?.id else { continue }
            
            do {
                let user = try await AuthService.shared.getUser(byId: userId)
                await MainActor.run {
                    loadedUsers[userId] = user
                }
            } catch {
                print("❌ Failed to load user \(userId): \(error)")
            }
        }
        
        await MainActor.run {
            isLoadingUsers = false
        }
    }
    
    private func getInitials(from user: User?) -> String {
        guard let user = user else { return "?" }
        let first = user.firstName.first.map(String.init) ?? ""
        let last = user.lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_FR")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    // Preview simple - Ride ne peut pas être initialisé directement
    Text("PendingParticipantsView Preview")
        .preferredColorScheme(.dark)
}
