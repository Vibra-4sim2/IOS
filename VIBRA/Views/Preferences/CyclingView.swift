//
//  CyclingView.swift
//  VIBRA
//

import SwiftUI

struct CyclingView: View {
    @Binding var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cycling Level").bold()
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

            Group {
                Text("Cycling Type").bold()
                Picker("Type", selection: Binding(get: { preferences.cyclingType }, set: { preferences.cyclingType = $0 })) {
                    Text("None").tag(CyclingType?.none)
                    ForEach(CyclingType.allCases) { t in
                        Text(t.rawValue).tag(CyclingType?.some(t))
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Text("Frequency").bold()
                Picker("Frequency", selection: Binding(get: { preferences.cyclingFrequency }, set: { preferences.cyclingFrequency = $0 })) {
                    Text("None").tag(CyclingFrequency?.none)
                    ForEach(CyclingFrequency.allCases) { f in
                        Text(f.rawValue).tag(CyclingFrequency?.some(f))
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Text("Distance").bold()
                Picker("Distance", selection: Binding(get: { preferences.cyclingDistance }, set: { preferences.cyclingDistance = $0 })) {
                    Text("None").tag(CyclingDistance?.none)
                    ForEach(CyclingDistance.allCases) { d in
                        Text(d.rawValue).tag(CyclingDistance?.some(d))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Toggle("Interested in Group?", isOn: Binding(get: {
                preferences.cyclingGroupInterest ?? false
            }, set: {
                preferences.cyclingGroupInterest = $0
            }))
        }
        .padding()
    }
}
