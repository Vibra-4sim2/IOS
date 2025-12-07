//
//  CampingView.swift
//  VIBRA
//
//  Created by mac book pro on 11/14/25.
//
import SwiftUI

struct CampingView: View {
    @Binding var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Camping Practice Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tent.fill")
                            .foregroundColor(AppColors.GreenAccent)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Practice Camping")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                            Text("Do you enjoy camping adventures?")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { preferences.campingPractice ?? false },
                            set: { preferences.campingPractice = $0 }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.GreenAccent))
                    }
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)

                if preferences.campingPractice ?? false {
                    // Camping Type Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(AppColors.TealAccent)
                            Text("Camping Type")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        Text("Choose your camping style")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                        
                        Picker("Type", selection: Binding(
                            get: { preferences.campingType },
                            set: { preferences.campingType = $0 }
                        )) {
                            Text("Select type").tag(CampingType?.none)
                            ForEach(CampingType.allCases, id: \.self) { t in
                                let label = (t == .CAMPING_CAR) ? "Camping-Car" : t.rawValue.capitalized
                                Text(label).tag(Optional.some(t))
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
                    .transition(.move(edge: .top).combined(with: .opacity))

                    // Camping Duration Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(AppColors.AmberAccent)
                            Text("Camping Duration")
                                .font(.headline)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        Text("How long do you usually camp?")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                        
                        Picker("Duration", selection: Binding(
                            get: { preferences.campingDuration },
                            set: { preferences.campingDuration = $0 }
                        )) {
                            Text("Select duration").tag(CampingDuration?.none)
                            ForEach(CampingDuration.allCases, id: \.self) { d in
                                Text(d.rawValue).tag(Optional.some(d))
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
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Tips Card
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(AppColors.WarningOrange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Camping Ready")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.TextPrimary)
                            Text("We'll recommend the best camping spots for you")
                                .font(.caption)
                                .foregroundColor(AppColors.TextSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(AppColors.WarningOrange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.WarningOrange.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(20)
            .animation(.spring(response: 0.3), value: preferences.campingPractice)
        }
        .background(Color.clear)
    }
}
