//
//  MatchDetailView.swift
//  VIBRA
//
//  Vue détaillée d'un match
//

import SwiftUI

struct MatchDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let match: UserMatch

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.BackgroundGradientStart, AppColors.BackgroundGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.TextSecondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(AppColors.CardDark)
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Profile Section
                    profileSection

                    // Match Score
                    matchScoreSection

                    // Preferences Comparison
                    preferencesSection

                    // Action Buttons
                    actionButtons
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Avatar
            Group {
                if let avatarURL = match.user.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            AppColors.CardDark
                            ProgressView()
                                .tint(AppColors.GreenAccent)
                        }
                    }
                } else {
                    ZStack {
                        AppColors.CardDark
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.TextTertiary)
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.GreenAccent, AppColors.TealAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
            .shadow(color: AppColors.GlowGreen, radius: 20)

            // Name
            Text(match.user.fullName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.TextPrimary)

            // Gender badge
            HStack(spacing: 8) {
                Image(systemName: match.user.gender.lowercased() == "male" ? "person.fill" : "person.fill")
                    .font(.system(size: 12))
                Text(match.user.gender.capitalized)
                    .font(.system(size: 14))
            }
            .foregroundColor(AppColors.TextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppColors.CardDark)
            )
        }
    }

    // MARK: - Match Score Section
    private var matchScoreSection: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(AppColors.CardDark, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: match.similarity)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.GreenAccent, AppColors.TealAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(match.similarityPercent)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.GreenAccent)

                    Text("Compatibilité")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.TextSecondary)
                }
            }
            .frame(width: 150, height: 150)

            Text("Algorithme: \(match.distance < 5 ? "Très proche" : "Compatible")")
                .font(.system(size: 14))
                .foregroundColor(AppColors.TextTertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .shadow(color: AppColors.ShadowColor, radius: 10)
        )
        .padding(.horizontal)
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparaison des préférences")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.TextPrimary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if let level = match.matchedPreferences.level {
                    PreferenceRow(title: "Niveau", value: level.safeValue, isMatch: level.safeMatch)
                }

                if let cyclingType = match.matchedPreferences.cyclingType {
                    PreferenceRow(title: "Type de vélo", value: cyclingType.safeValue, isMatch: cyclingType.safeMatch)
                }

                if let cyclingFreq = match.matchedPreferences.cyclingFrequency {
                    PreferenceRow(
                        title: "Fréquence vélo",
                        value: cyclingFreq.displayValue,
                        isMatch: cyclingFreq.safeMatch,
                        subtitle: cyclingFreq.comparisonText
                    )
                }

                if let hikeType = match.matchedPreferences.hikeType {
                    PreferenceRow(
                        title: "Type de randonnée",
                        value: hikeType.displayValue,
                        isMatch: hikeType.safeMatch,
                        subtitle: hikeType.comparisonText
                    )
                }

                if let hikeDuration = match.matchedPreferences.hikeDuration {
                    PreferenceRow(
                        title: "Durée randonnée",
                        value: hikeDuration.displayValue,
                        isMatch: hikeDuration.safeMatch,
                        subtitle: hikeDuration.comparisonText
                    )
                }

                if let hikePreference = match.matchedPreferences.hikePreference {
                    PreferenceRow(title: "Préférence rando", value: hikePreference.safeValue, isMatch: hikePreference.safeMatch)
                }

                if let camping = match.matchedPreferences.campingPractice {
                    PreferenceRow(title: "Pratique camping", value: camping.safeValue ? "Oui" : "Non", isMatch: camping.safeMatch)
                }

                if let campingType = match.matchedPreferences.campingType {
                    PreferenceRow(
                        title: "Type de camping",
                        value: campingType.displayValue,
                        isMatch: campingType.safeMatch,
                        subtitle: campingType.comparisonText
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.CardDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.BorderColor, lineWidth: 1)
                    )
                    .shadow(color: AppColors.ShadowColor, radius: 10)
            )
            .padding(.horizontal)
        }
    }

    // ...
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Message button
            /*Button(action: {
                // TODO: Implement messaging
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                    Text("Envoyer un message")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppColors.TextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.GreenAccent, AppColors.TealAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AppColors.GlowGreen, radius: 10)
                )
            }*/

            // View profile button -> ouvre la page de profil standard avec l'userId du match
            NavigationLink(destination: ProfileView(userId: match.userId)) {
                HStack {
                    Image(systemName: "person.circle")
                        .font(.system(size: 16))
                    Text("Voir le profil complet")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppColors.TextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.CardDark)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.GreenAccent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal)
    }
    // ...
    // MARK: - Preference Row
    struct PreferenceRow: View {
        let title: String
        let value: String
        let isMatch: Bool
        var subtitle: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.TextSecondary)

                        Text(value)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.TextPrimary)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.TextTertiary)
                        }
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(isMatch ? AppColors.SuccessGreen.opacity(0.2) : AppColors.CardOverlay)
                            .frame(width: 36, height: 36)

                        Image(systemName: isMatch ? "checkmark" : "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isMatch ? AppColors.SuccessGreen : AppColors.TextTertiary)
                    }
                }

                if !isMatch {
                    Divider()
                        .background(AppColors.DividerColor)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MatchDetailView(match: UserMatch(
        userId: "123",
        similarity: 0.205,
        similarityPercent: "20.5%",
        distance: 3.86,
        user: MatchedUser(
            id: "123",
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            avatar: "",
            gender: "MALE"
        ),
        matchedPreferences: MatchedPreferences(
            level: PreferenceMatch(value: "BEGINNER", match: true),
            cyclingType: PreferenceMatch(value: "VTT", match: true),
            cyclingFrequency: PreferenceMatchWithValues(userValue: "HEBDO", matchValue: "QUOTIDIEN", value: nil, match: false),
            hikeType: PreferenceMatchWithValues(userValue: "COURTE", matchValue: "MONTAGNE", value: nil, match: false),
            hikeDuration: PreferenceMatchWithValues(userValue: nil, matchValue: nil, value: "2-4H", match: true),
            hikePreference: PreferenceMatch(value: "GROUPE", match: true),
            campingPractice: BooleanPreferenceMatch(value: true, match: true),
            campingType: PreferenceMatchWithValues(userValue: "VAN", matchValue: "TENTE", value: nil, match: false)
        )
    ))
}
