//
//  HikingView.swift
//  VIBRA
//

import SwiftUI

struct HikingView: View {
    @Binding var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hike Type Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.hiking")
                            .foregroundColor(AppColors.GreenAccent)
                        Text("Hike Type")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                    }
                    
                    Picker("Type", selection: Binding(get: { preferences.hikeType }, set: { preferences.hikeType = $0 })) {
                        Text("Select type").tag(HikeType?.none)
                        ForEach(HikeType.allCases) { t in
                            Text(t.rawValue).tag(HikeType?.some(t))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(12)
                    .background(AppColors.BackgroundDark)
                    .cornerRadius(10)
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)
                
                // Duration Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.TealAccent)
                        Text("Duration")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                    }
                    
                    Picker("Duration", selection: Binding(get: { preferences.hikeDuration }, set: { preferences.hikeDuration = $0 })) {
                        Text("Select duration").tag(HikeDuration?.none)
                        ForEach(HikeDuration.allCases) { d in
                            Text(d.rawValue).tag(HikeDuration?.some(d))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(12)
                    .background(AppColors.BackgroundDark)
                    .cornerRadius(10)
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)
                
                // Preference Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppColors.GreenAccent)
                        Text("Preference")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                    }
                    
                    Text("Choose your hiking style")
                        .font(.caption)
                        .foregroundColor(AppColors.TextSecondary)
                    
                    Picker("Preference", selection: Binding(get: { preferences.hikePreference }, set: { preferences.hikePreference = $0 })) {
                        Text("None").tag(HikePreference?.none)
                        ForEach(HikePreference.allCases) { p in
                            Text(p.rawValue).tag(HikePreference?.some(p))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(AppColors.CardDark)
                    .cornerRadius(8)
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)
                
                // Info Card
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.InfoBlue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hiking Tips")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.TextPrimary)
                        Text("We'll match you with trails based on your preferences")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(AppColors.InfoBlue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.InfoBlue.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .padding(20)
        }
        .background(Color.clear)
    }
}
