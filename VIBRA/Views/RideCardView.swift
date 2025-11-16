//
//  RideCardView.swift
//  VIBRA
//
//  Created by GitHub Copilot on 11/16/25.
//

import SwiftUI

struct RideCardView: View {
    let item: RideWithCreator

    var body: some View {
        cardContent
            .frame(height: 240)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
            .overlay(cardBorder)
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: Color.green.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Main Card Content
    
    private var cardContent: some View {
        ZStack(alignment: .topLeading) {
            rideImageView
            activityBadge
            bottomInfoSection
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Image Section
    
    private var rideImageView: some View {
        Group {
            if let photo = item.ride.photo, let url = URL(string: photo) {
                AsyncImage(url: url) { phase in
                    imagePhaseView(phase)
                }
                .frame(height: 240)
                .clipped()
            } else {
                placeholderImageView
            }
        }
    }
    
    private func imagePhaseView(_ phase: AsyncImagePhase) -> some View {
        Group {
            switch phase {
            case .empty:
                loadingImageView
            case .success(let image):
                successImageView(image)
            case .failure:
                failureImageView
            @unknown default:
                Color.gray.opacity(0.2)
            }
        }
    }
    
    private var loadingImageView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
    
    private func successImageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .overlay(imageGradient)
    }
    
    private var imageGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.7),
                Color.black.opacity(0.4),
                Color.clear,
                Color.black.opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var failureImageView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                Text("Image non disponible")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var placeholderImageView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                Text("Pas de photo")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(height: 240)
    }
    
    // MARK: - Activity Badge
    
    private var activityBadge: some View {
        HStack(spacing: 8) {
            if let type = item.ride.type {
                HStack(spacing: 4) {
                    Image(systemName: activityIcon(for: type))
                        .font(.system(size: 12, weight: .semibold))
                    Text(type)
                        .font(.system(size: 12, weight: .bold))
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(typeColor(for: type))
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            Spacer()
        }
        .padding([.top, .leading], 12)
    }
    
    // MARK: - Bottom Info Section
    
    private var bottomInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                titleView
                creatorInfoSection
                dateTimeRow
                distanceDifficultyRow
            }
            .padding(16)
            .background(bottomGradient)
        }
    }
    
    private var bottomGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.0),
                Color.black.opacity(0.7)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var titleView: some View {
        Text(item.ride.titre)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Creator Section
    
    private var creatorInfoSection: some View {
        HStack(spacing: 10) {
            creatorAvatarView
            creatorNameSection
            Spacer()
            participantsBadge(for: item.ride)
        }
    }
    
    private var creatorAvatarView: some View {
        Group {
            if let avatar = item.creator?.avatar, let avatarURL = URL(string: avatar) {
                AsyncImage(url: avatarURL) { phase in
                    avatarPhaseView(phase)
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(avatarBorder)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                defaultAvatarView
            }
        }
    }
    
    private func avatarPhaseView(_ phase: AsyncImagePhase) -> some View {
        Group {
            switch phase {
            case .empty:
                loadingAvatarView
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure:
                failedAvatarView
            @unknown default:
                Circle().fill(Color.gray.opacity(0.4))
            }
        }
    }
    
    private var loadingAvatarView: some View {
        Circle()
            .fill(avatarGradient)
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.6)
            )
    }
    
    private var failedAvatarView: some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 18))
            )
    }
    
    private var defaultAvatarView: some View {
        Circle()
            .fill(avatarGradient)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 20))
            )
            .overlay(avatarBorder)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var avatarGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var avatarBorder: some View {
        Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
    }
    
    private var creatorNameSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(creatorFullName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                Text("Organisateur")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Participants Badge
    private func participantsBadge(for ride: Ride) -> some View {
        let current = participantsCount(for: ride)
        let cap = ride.capacite
        return HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
            Text(cap != nil ? "\(current) / \(cap!)" : "\(current)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func participantsCount(for ride: Ride) -> Int {
        let usersCount = ride.participants?.count ?? 0
        let idsCount = ride.participantIds?.count ?? 0
        return max(usersCount, idsCount)
    }
    
    // MARK: - Date & Time Row
    
    private var dateTimeRow: some View {
        HStack(spacing: 10) {
            if let date = item.ride.date {
                dateBadge(date)
                timeBadge(date)
            }
            Spacer()
        }
        .padding(.top, 4)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    private func dateBadge(_ date: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "calendar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.green)
            Text(formatDateOnly(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }
    
    private func timeBadge(_ date: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)
            Text(formatTimeOnly(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }
    
    // MARK: - Distance Row
    
    private var distanceDifficultyRow: some View {
        HStack(spacing: 10) {
            if let distance = item.ride.distance { distanceBadge(distance) }
            // Camping indicator
            if includesCamping(item.ride) { campingBadge }
            if let difficulte = item.ride.difficulte, !difficulte.isEmpty { difficultyBadge(difficulte) }
            Spacer()
        }
        .padding(.top, 4)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    // Camping badge
    private var campingBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "tent.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)
            Text("Camping")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.25))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func includesCamping(_ ride: Ride) -> Bool {
        if let flag = ride.optionCamping, flag { return true }
        if ride.campingId != nil { return true }
        if ride.camping != nil { return true }
        return false
    }
    
    private func distanceBadge(_ distance: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "location.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.blue)
            Text(distanceText(from: distance))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.15))
        .cornerRadius(8)
    }
    
    private func difficultyBadge(_ difficulty: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(difficultyColor(for: difficulty))
            Text(difficulty.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(difficultyColor(for: difficulty).opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(difficultyColor(for: difficulty).opacity(0.4), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Properties & Functions
    
    private var creatorFullName: String {
        if let creator = item.creator {
            let firstName = creator.firstName
            let lastName = creator.lastName
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let creatorId = item.ride.createurId {
            return "Utilisateur #\(creatorId.prefix(8))"
        } else {
            return "Utilisateur inconnu"
        }
    }
    
    private func distanceText(from meters: Int) -> String {
        if meters >= 1000 {
            let km = Double(meters) / 1000.0
            return String(format: "%.1f km", km)
        }
        return "\(meters) m"
    }
    
    private func formatDateOnly(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func formatTimeOnly(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
        return ""
    }
    
    private func typeColor(for type: String) -> Color {
        switch type.uppercased() {
        case "CAMPING":
            return Color.orange
        case "RANDONNEE", "RANDONNÉE", "HIKING":
            return Color.green
        case "VELO", "VÉLO", "CYCLING":
            return Color.blue
        default:
            return Color.purple
        }
    }
    
    private func activityIcon(for type: String) -> String {
        switch type.uppercased() {
        case "CAMPING":
            return "tent.fill"
        case "RANDONNEE", "RANDONNÉE", "HIKING":
            return "figure.hiking"
        case "VELO", "VÉLO", "CYCLING":
            return "bicycle"
        default:
            return "star.fill"
        }
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "facile", "easy", "débutant", "beginner":
            return Color.green
        case "moyen", "moyenne", "medium", "intermédiaire", "intermediate":
            return Color.yellow
        case "difficile", "hard", "expert", "avancé", "advanced":
            return Color.red
        default:
            return Color.orange
        }
    }
}
