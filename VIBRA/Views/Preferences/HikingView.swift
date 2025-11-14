//
//  HikingView.swift
//  VIBRA
//

import SwiftUI

struct HikingView: View {
    @Binding var preferences: Preferences

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hike Type").bold()
            Picker("Type", selection: Binding(get: { preferences.hikeType }, set: { preferences.hikeType = $0 })) {
                Text("None").tag(HikeType?.none)
                ForEach(HikeType.allCases) { t in
                    Text(t.rawValue).tag(HikeType?.some(t))
                }
            }
            .pickerStyle(MenuPickerStyle())

            Text("Duration").bold()
            Picker("Duration", selection: Binding(get: { preferences.hikeDuration }, set: { preferences.hikeDuration = $0 })) {
                Text("None").tag(HikeDuration?.none)
                ForEach(HikeDuration.allCases) { d in
                    Text(d.rawValue).tag(HikeDuration?.some(d))
                }
            }
            .pickerStyle(MenuPickerStyle())

            Text("Preference").bold()
            Picker("Preference", selection: Binding(get: { preferences.hikePreference }, set: { preferences.hikePreference = $0 })) {
                Text("None").tag(HikePreference?.none)
                ForEach(HikePreference.allCases) { p in
                    Text(p.rawValue).tag(HikePreference?.some(p))
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}
