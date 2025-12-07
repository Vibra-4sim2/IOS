//
//  CyclingView.swift
//  VIBRA
//

import SwiftUI

struct CyclingView: View {
    @Binding var preferences: Preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Cycling Level Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(AppColors.GreenAccent)
                        Text("Cycling Level")
                            .font(.headline)
                            .foregroundColor(AppColors.TextPrimary)
                    }
                    
                    Picker("Level", selection: Binding(get: {
                        preferences.level
                    }, set: { newValue in
                        preferences.level = newValue
                    })) {
                        Text("None").tag(Level?.none)
                        ForEach(Level.allCases) { level in
                            Text(level.rawValue.capitalized).tag(Level?.some(level))
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
                
                // Cycling Details Card
                VStack(alignment: .leading, spacing: 20) {
                    // Type
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bicycle")
                                .foregroundColor(AppColors.TealAccent)
                            Text("Cycling Type")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        Picker("Type", selection: Binding(get: { preferences.cyclingType }, set: { preferences.cyclingType = $0 })) {
                            Text("Select type").tag(CyclingType?.none)
                            ForEach(CyclingType.allCases) { t in
                                Text(t.rawValue).tag(CyclingType?.some(t))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(12)
                        .background(AppColors.BackgroundDark)
                        .cornerRadius(10)
                    }
                    
                    Divider()
                        .background(AppColors.DividerColor)
                    
                    // Frequency
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppColors.TealAccent)
                            Text("Frequency")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        Picker("Frequency", selection: Binding(get: { preferences.cyclingFrequency }, set: { preferences.cyclingFrequency = $0 })) {
                            Text("Select frequency").tag(CyclingFrequency?.none)
                            ForEach(CyclingFrequency.allCases) { f in
                                Text(f.rawValue).tag(CyclingFrequency?.some(f))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(12)
                        .background(AppColors.BackgroundDark)
                        .cornerRadius(10)
                    }
                    
                    Divider()
                        .background(AppColors.DividerColor)
                    
                    // Distance
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(AppColors.TealAccent)
                            Text("Distance")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        
                        Picker("Distance", selection: Binding(get: { preferences.cyclingDistance }, set: { preferences.cyclingDistance = $0 })) {
                            Text("Select distance").tag(CyclingDistance?.none)
                            ForEach(CyclingDistance.allCases) { d in
                                Text(d.rawValue).tag(CyclingDistance?.some(d))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(12)
                        .background(AppColors.BackgroundDark)
                        .cornerRadius(10)
                    }
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)
                
                // Group Interest Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(AppColors.GreenAccent)
                            Text("Join Group Rides")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.TextPrimary)
                        }
                        Text("Connect with other cyclists")
                            .font(.caption)
                            .foregroundColor(AppColors.TextSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(get: {
                        preferences.cyclingGroupInterest ?? false
                    }, set: {
                        preferences.cyclingGroupInterest = $0
                    }))
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.GreenAccent))
                }
                .padding(16)
                .background(AppColors.CardDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.BorderColor, lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .padding(20)
        }
        .background(Color.clear)
    }
}
