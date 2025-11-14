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
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Do you practice camping?", isOn: Binding(
                get: { preferences.campingPractice ?? false },
                set: { preferences.campingPractice = $0 }
            ))

            if preferences.campingPractice ?? false {
                Text("Camping Type").bold()
                Picker("Type", selection: Binding(get: { preferences.campingType }, set: { preferences.campingType = $0 })) {
                    Text("None").tag(CampingType?.none)
                    ForEach(CampingType.allCases, id: \.self) { t in
                        let label = (t == .CAMPING_CAR) ? "Camping-Car" : t.rawValue.capitalized
                        Text(label).tag(Optional.some(t))
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Text("Camping Duration").bold()
                Picker("Duration", selection: Binding(get: { preferences.campingDuration }, set: { preferences.campingDuration = $0 })) {
                    Text("None").tag(CampingDuration?.none)
                    ForEach(CampingDuration.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(Optional.some(d))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
    }
}
